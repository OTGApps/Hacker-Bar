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

  def start_polling
    ap "Starting to poll"
    NSLog "Starting to poll"
  	if @timer.nil? || !@timer.isValid
      interval = App::Persistence['check_interval'];
      ap "Wait #{interval} seconds"
      @timer = NSTimer.scheduledTimerWithTimeInterval(interval, target:self, selector:"go_go_gadget_scheduler", userInfo:nil, repeats:true)
  	end
  end

  def stop_polling
    ap "Stopping the polling"
    NSLog "Stopping the polling"
    @timer.invalidate
  end

  def restart_polling
  	stop_polling
  	start_polling
  end

  def go_go_gadget_scheduler
  	ap "Refreshing"
    App.delegate.refresh
  end

  def failsafe
  	# Don't hammer our server please.
  	if App::Persistence['check_interval'] < 60
  		App::Persistence['check_interval'] = 60
	    alert = NSAlert.alloc.init
	    alert.setMessageText "Please don't try and fetch data from our server more often than every 60 seconds.\n\nThanks!"
	    alert.addButtonWithTitle "OK, I'm sorry"
	    alert.runModal
  	end
  end

end
