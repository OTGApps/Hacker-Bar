class AppDelegate
  def applicationDidFinishLaunching(notification)
    app_name = "Hacker\ Bar"
    unless NSWorkspace.sharedWorkspace.launchApplication(app_name)
      NSLog "Could not open app with name #{app_name} - is the name correct?"
    end
    NSApp.performSelector("terminate:", withObject:nil, afterDelay: 0.0)
  end
end
