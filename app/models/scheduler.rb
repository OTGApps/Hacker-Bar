class Scheduler

  attr_accessor :timer

  def self.shared_scheduler
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
  	ap "Init scheduler"
		failsafe
  end

  def refresh_and_start_polling
    App.delegate.refresh
    start_polling
  end

  def start_polling
    ap "Starting to poll"
    NSLog "Starting to poll"

    EM.cancel_timer(@timer) if @timer

    if @timer.nil?
      interval = App::Persistence['check_interval'];
      ap "Wait #{interval} seconds"

      @timer = EM.add_periodic_timer interval do
        ap "Refreshing at #{Time.now}"
        App.delegate.refresh
      end
  	end
  end

  def stop_polling
    ap "Stopping the polling"
    NSLog "Stopping the polling"
    EM.cancel_timer(@timer)
    @timer = nil
  end

  def restart_polling
  	stop_polling
  	start_polling
  end

  def failsafe
  	interval = App::Persistence['check_interval']
    # Don't hammer our server please.
  	if interval > 0 && interval < 60
  		interval = 60
	    alert = NSAlert.alloc.init
	    alert.setMessageText "Please don't try and fetch data from our server more often than every 60 seconds.\n\nThanks!"
	    alert.addButtonWithTitle "OK, I'm sorry"
	    alert.runModal
  	end
  end

end
