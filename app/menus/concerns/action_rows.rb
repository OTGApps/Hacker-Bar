module ActionRows
  include RefreshRows

  def action_sections
    [{
      rows: [{
        title: 'Preferences:',
        enabled: false
      }, {
        title: "Launch #{App.name} On Login",
        target: self,
        action: "toggle_autolaunch:",
        checked: App::Persistence['launch_on_login']
      }, {
        title: 'Refresh Interval:',
        rows: refresh_sections
      }]
    }, {
      rows: [{
        title: "About #{App.name}",
        target: self,
        action: "show_about_window:"
      }, {
        title: "Visit news.ycombinator.com",
        target: self,
        action: :visit_hackernews
      }, {
        title: "Quit",
        action: "terminate:"
      }]
    }]
  end

  def show_about_window(sender)
    Mixpanel.sharedInstance.track("Show About") unless BW.debug?
    NSApplication.sharedApplication.activateIgnoringOtherApps(true)
    NSApp.orderFrontStandardAboutPanel(sender)
    NSApp.activateIgnoringOtherApps(true)
  end

  def visit_hackernews
    NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString("https://news.ycombinator.com/"))
  end

  def toggle_autolaunch(sender)
    autolaunch = !App::Persistence['launch_on_login']
    App::Persistence['launch_on_login'] = autolaunch
    start_at_login autolaunch

    # Set the checkmark wihtout reloading the entire menu and causing network traffic
    sender.setState (autolaunch == true) ? NSOnState : NSOffState unless sender.nil?
  end

  def start_at_login(enabled)
    Mixpanel.sharedInstance.track("Setting Autolaunch", properties:{autolaunch:enabled}) unless BW.debug?
    url = NSBundle.mainBundle.bundleURL.URLByAppendingPathComponent("Contents/Library/LoginItems/HackerBarLauncher.app", isDirectory:true)

    status = LSRegisterURL(url, true)
    unless status
      NSLog("Failed to LSRegisterURL '%@': %jd", url, status)
      return
    end

    success = SMLoginItemSetEnabled("com.mohawkapps.hackerbarlauncher", enabled)
    unless success
      NSLog("Failed to start #{App.name} launch helper.")
      return
    end
  end
end
