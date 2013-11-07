class Scheduler

  attr_accessor :timer

  def self.shared_scheduler
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
		failsafe
  end

  def refresh_and_start_polling
    App.delegate.refresh
    start_polling
  end

  def start_polling
    NSLog "Starting to poll"

    EM.cancel_timer(@timer) if @timer

    if @timer.nil?
      interval = App::Persistence['check_interval'];
      ap "Wait #{interval} seconds" if BubbleWrap.debug?

      @timer = EM.add_periodic_timer interval do
        ap "Refreshing at #{Time.now}" if BubbleWrap.debug?
        App.delegate.refresh

        stop_polling if App::Persistence['check_interval'] == 0
      end
  	end
  end

  def stop_polling
    NSLog "Stop the polling"
    EM.cancel_timer(@timer)
    @timer = nil
  end

  def restart_polling
  	stop_polling
  	start_polling
  end

  def active
    !@timer.nil?
  end

  def failsafe
    # Don't hammer our server please.
  	if App::Persistence['check_interval'] < 60
  		App::Persistence['check_interval'] = 60
  	end
  end

end
