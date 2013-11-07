class GATracker

  attr_accessor :t

  def self.shared_tracker
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    @t = GAJavaScriptTracker.trackerWithAccountID("UA-45525710-1")
    unless NSBundle.mainBundle.objectForInfoDictionaryKey('AppStoreRelease') == true
      ap "Init Analytics in Debug Mode"
      @t.debug = true
      @t.dryRun = true
    else
    end
    @t.anonymizeIp = true
    @t.batchSize = 10
  end

  def start
    @t.start
  end

  def stop
    unless @t.isRunning
        NSLog("Tracker already stopped")
        return
    end

    @t.stop
  end

  def track(args)
    args = {
      label: "tackEvent",
      value: -1
      }.merge(args)

    raise "You must specify an event and action for a tracking event." unless args[:event] && args[:action]

    @t.trackEvent(args[:event], action:args[:action], label:args[:label], value:args[:value], withError:nil)
  end


end
