class AppDelegate
  def applicationDidFinishLaunching(notification)
    app_name = "Hacker\ Bar"
    if NSWorkspace.sharedWorkspace.launchApplication(app_name)
      NSApp.performSelector("terminate:", withObject:nil, afterDelay: 0.0)
    else
      raise "Could not open app with name #{app_name} - is the name correct?"
    end
  end
end
