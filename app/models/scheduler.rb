class Scheduler

  attr_accessor :timer

  def self.shared_scheduler
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
		failsafe
  end

  def refresh_and_trigger
    App.delegate.refresh
    trigger_wait
  end

  def trigger_wait
    interval = App::Persistence['check_interval'].to_i;
    return if interval == 0

    ap "Wait #{interval} seconds" if BubbleWrap.debug?

    @timer = EM.add_timer interval do
      ap "Refreshing at #{Time.now}" if BubbleWrap.debug?
      App.delegate.refresh
    end
  end

  def stop_waiting
    NSLog "Stop the waiting"
    EM.cancel_timer(@timer)
    @timer = nil
  end

  def last_check
    "Updated " << Time.at(App::Persistence['last_check'].to_i).distanceOfTimeInWords
  end

  def failsafe
    # Don't hammer our server please.
  	if App::Persistence['check_interval'].to_i < 60
  		App::Persistence['check_interval'].to_i = 60

      EM.schedule do
        alert = NSAlert.alloc.init
        alert.setMessageText "Please don't try and fetch data from our server more often than every 60 seconds.\n\nThanks!"
        alert.addButtonWithTitle "OK, I'm sorry"
        alert.runModal
      end

  	end
  end

end
