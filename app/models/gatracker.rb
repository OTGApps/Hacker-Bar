class GATracker

  attr_accessor :t

  def self.shared_tracker
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    @t = BSWebTracker.new
    @t.trackerURLString = "http://hackerbartracker.mohawkapps.com/"
  end

  def track(args)
    args = {
      value: -1
      }.merge(args)

    raise "You must specify an event and action for a tracking event." unless args[:event] && args[:action]

    @t.trackName(args[:event].to_s, content:args[:action].to_s, term:args[:value].to_s)
  end

end
