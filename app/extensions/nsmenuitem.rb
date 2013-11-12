# http://kickcode.com/blog/2013/11/07/rubymotion-background-process-in-status-bar-app.html
class NSMenuItem
  def checked
    self.state == NSOnState
  end

  def checked=(value)
    self.state = (value ? NSOnState : NSOffState)
  end
end
