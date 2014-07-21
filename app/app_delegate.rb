class AppDelegate
  def applicationDidFinishLaunching(notification)
    setup

    status_item.setMenu(main_menu)
    status_item.highlightMode = true
    status_item.toolTip = App.name
    update_status_item
    true
  end

  def applicationWillTerminate(notification)
    Mixpanel.sharedInstance.track("App Quit") unless BW.debug?
  end

  def setup
    unless App.info_plist['AppStoreRelease'] == true
      BW.debug = true
    else
      Mixpanel.sharedInstanceWithToken("69f9ad8b0b4679373d3a790ff5393b20")
      mixpanel = Mixpanel.sharedInstance
      mixpanel.identify(Machine.unique_id)
    end

    App::Persistence['check_interval'] ||= 300 # In seconds
    App::Persistence['launch_on_login'] ||= false
    App::Persistence['clicked'] ||= []

    if App::Persistence['asked_to_launch_on_login'] != true
      App::Persistence['asked_to_launch_on_login'] = true

      # Ask the user to launch the app on start.
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle('Yes')
      alert.addButtonWithTitle('No')
      alert.setMessageText("Launch #{App.name} on login?")
      alert.setInformativeText("Would you like #{App.name} to automatically launch on login?")
      alert.setAlertStyle(NSWarningAlertStyle)

      main_menu.toggle_autolaunch(nil) if alert.runModal == NSAlertFirstButtonReturn
    end
  end

  def main_menu
    @main_menu ||= MainMenu.new
  end

  def status_item
    @status_item ||= begin
      status_item = NSStatusBar.systemStatusBar.statusItemWithLength(NSSquareStatusItemLength).init
      status_item.setHighlightMode(true)
      status_item
    end
  end

  def update_status_item(image = 'Status', alternate_image = 'StatusHighlighted')
    status_item.setImage(NSImage.imageNamed(image))
    status_item.setAlternateImage(NSImage.imageNamed(alternate_image))
  end

end
