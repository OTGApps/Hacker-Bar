class AppDelegate
  attr_accessor :status_item, :menu, :items, :highlighted_item, :menu_open

  def applicationDidFinishLaunching(notification)

    BW.debug = true unless NSBundle.mainBundle.objectForInfoDictionaryKey('AppStoreRelease') == true

    Mixpanel.sharedInstanceWithToken("69f9ad8b0b4679373d3a790ff5393b20")
    mixpanel = Mixpanel.sharedInstance
    mixpanel.identify(Machine.unique_id)

    @menu = NSMenu.new
    @menu.setAutoenablesItems true
    @menu.delegate = self

    @menu_open = false

    @items = []
    App::Persistence['check_interval'] ||= 300 # In seconds
    App::Persistence['launch_on_login'] ||= false
    App::Persistence['clicked'] ||= []

    @status_bar ||= NSStatusBar.systemStatusBar
    @status_item ||= @status_bar.statusItemWithLength(NSSquareStatusItemLength)
    @status_item.menu = @menu
    @status_item.highlightMode = true
    @status_item.toolTip = App.name
    reset_image

    update_menu

    invocation = NSInvocation.invocationWithMethodSignature(self.methodSignatureForSelector("update_interface_last_updated:"))
    invocation.setTarget(self)
    invocation.setSelector("update_interface_last_updated:")
    NSRunLoop.mainRunLoop.addTimer(NSTimer.timerWithTimeInterval(5, invocation:invocation, repeats:true), forMode:NSRunLoopCommonModes)

    NSNotificationCenter.defaultCenter.addObserver(self, selector:"network_status_changed:", name:FXReachabilityStatusDidChangeNotification, object:nil)

    if App::Persistence['asked_to_launch_on_login'] != true
      App::Persistence['asked_to_launch_on_login'] = true

      # Ask the user to launch the app on start.
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle("Yes")
      alert.addButtonWithTitle("No")
      alert.setMessageText("Launch #{App.name} on login?")
      alert.setInformativeText("Would you like #{App.name} to automatically launch on login?")
      alert.setAlertStyle(NSWarningAlertStyle)

      toggle_autolaunch(nil) if alert.runModal == NSAlertFirstButtonReturn
    end

  end

  def applicationWillTerminate(notification)
    Mixpanel.sharedInstance.track("App Quit")
    Scheduler.shared_scheduler.stop_waiting
  end

  def update_menu
    @menu.removeAllItems

    @items.each do |news_item|
      tag = news_item.hnitem.id || rand(-999)
      @menu.addItem create_item(object:news_item, tag:tag.to_i, enabled:true, action:"blank_action:")
    end
    add_bottom_menu_items
  end

  def add_bottom_menu_items
    @menu.addItem NSMenuItem.separatorItem
    @menu.addItem create_item(title: "Preferences:", enabled: false)
    @menu.addItem create_item(title: " Launch #{App.name} on login", action: "toggle_autolaunch:", checked: App::Persistence['launch_on_login'])
    @menu.addItem create_refresh_option_menu

    @menu.addItem NSMenuItem.separatorItem
    @menu.addItem create_item(title: "About #{App.name}", action:'show_about:')
    @menu.addItem create_item(title: "Quit", action:'terminate:')
  end

  def create_refresh_option_menu
    refresh_options = NSMenuItem.alloc.init
    refresh_options.setTitle(" Refresh Options")
    @sub_options ||= NSMenu.alloc.init
    @sub_options.removeAllItems
    @sub_options.setAutoenablesItems true

    # Auto-updating last check menu item
    @last_check_item ||= create_item(title: Scheduler.shared_scheduler.last_check_words, enabled: false)
    @sub_options.addItem @last_check_item
    @sub_options.addItem NSMenuItem.separatorItem

    refresh_menu_options.each do |option|
      @sub_options.addItem option
    end

    refresh_options.setSubmenu(@sub_options)
    refresh_options
  end

  def refresh_menu_options
    items = []
    # items << create_item(title: " Refresh Now", action:'refresh', image: 'refresh')
    # items << NSMenuItem.separatorItem
    [
      [' 5 minutes', 300],
      [' 10 Minutes', 600],
      [' 30 minutes', 1800],
      [' 1 hour', 3600],
      [' 2 hours', 7200]
    ].each do |value|

      current_interval = (value[1] == App::Persistence['check_interval'])
      action = (current_interval) ? nil : "update_fetch_time:"

      option = NSMenuItem.alloc.initWithTitle(value[0], action:action , keyEquivalent: '')
      option.tag = value[1]

      option.checked = current_interval
      option.setEnabled !current_interval
      items << option
    end

    items
  end

  def update_fetch_time sender
    NSLog "Updating fetch time to #{sender.tag}"
    time = sender.tag.to_i

    previous_time = App::Persistence['check_interval']
    App::Persistence['check_interval'] = time

    if time > 0 && network_reachable
      Scheduler.shared_scheduler.refresh_and_trigger
    end

    Mixpanel.sharedInstance.track("Update Fetch Interval", properties:{from:previous_time, to:time})

    # Rebuild the interface
    @sub_options.removeAllItems
    refresh_menu_options.each do |option|
      @sub_options.addItem option
    end
  end

  def refresh
    NSLog "Refreshing the menu" if BW.debug?

    if network_reachable
      NSLog "Network is reachable. Fetching data." if BW.debug?
      fetch
    else
      NSLog "Network is NOT reachable. Displaying message." if BW.debug?
      Scheduler.shared_scheduler.stop_waiting
      @menu.removeAllItems
      @menu.addItem create_item(title: "Network is offline.", enabled: false)
      add_bottom_menu_items
    end
  end

  def create_item(args={})
    args = {
      key:'',
      action: nil,
      enabled: true
      }.merge(args)
    args[:title] = args[:object].hnitem.title if args[:object]

    item = NSMenuItem.alloc.initWithTitle(args[:title], action: args[:action], keyEquivalent: args[:key])
    item.tag = args[:tag] if args[:tag]

    item.setEnabled(args[:enabled])

    if args[:object]
      args[:object].tag = args[:tag] if args[:tag]
      item.setView args[:object].view
    end

    args[:image] = "check" if args[:checked]

    # Image
    if args[:image]
      if args[:image] == "check"
        item.checked = true
      else
        i = args[:image].image
        item.setOffStateImage i
        item.setOnStateImage i
        item.onStateImage.setTemplate(true)
      end
    end

    item
  end

  # Animated icon while the API is pulling new results
  def animate_icon
    NSLog "Starting image animation" if BW.debug?
    @current_frame = 0

    @icon_animation_timer = EM.add_periodic_timer 1.0/8.0 do
      # get the image for the current frame
      image = "StatusAnimating_#{@current_frame}".image
      @status_item.setImage(image)
      if @current_frame == 7
        @current_frame = 0
      else
        @current_frame = @current_frame + 1
      end
    end
  end

  def reset_image
    NSLog "Resetting the icon." if BW.debug?
    EM.cancel_timer(@icon_animation_timer) if @icon_animation_timer
    @status_item.image = "Status".image
    @status_item.alternateImage = "StatusHighlighted".image
  end

  def blank_action(sender)
    # Whatever
  end

  def toggle_autolaunch sender
    autolaunch = !App::Persistence['launch_on_login']
    App::Persistence['launch_on_login'] = autolaunch
    start_at_login autolaunch
    sender.setState (autolaunch == true) ? NSOnState : NSOffState unless sender.nil?
  end

  # TODO: Get this working properly.
  def start_at_login enabled
    Mixpanel.sharedInstance.track("Setting Autolaunch", properties:{autolaunch:enabled})
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

  private
  # Don't ever call this method directly. Use the refresh method
  def fetch
    NSLog "Fetching new data" if BW.debug?

    if @menu_open
      NSLog "Menu is open. Not refreshing, just resetting the timer." if BW.debug?
      Scheduler.shared_scheduler.trigger_wait
      return
    end

    animate_icon
    HNAPI.get_news do |json, error|
      if error.nil? && json.count > 0
        json['submissions'].each_with_index do |news, i|
          this_hn_item = HNItem.new(news)
          if @items[i].nil? || (!@highlighted_item.nil? && @highlighted_item.hnitem == this_hn_item)
            news_item = HNItemViewController.alloc.initWithNibName("HNItemViewController", bundle:nil)
            news_item.hnitem = this_hn_item
            @items[i] = news_item
          else
            @items[i].hnitem = this_hn_item
          end
        end
        # Mixpanel.sharedInstance.track("API Hit")
        App::Persistence['last_check'] = Time.now.to_i
        update_interface_last_updated nil
        update_menu
      else
        NSLog("Error: Could not get data from API")
        error_string = "Error: #{error.description}"
        unless error['error'].nil?
          api_error error['error']
          NSLog("API Error: #{error['error']['message']}")
          Mixpanel.sharedInstance.track("API Error", properties:error['error'])
        end
      end
      reset_image
      Scheduler.shared_scheduler.trigger_wait
    end
  end

  def api_error error
    @status_item.toolTip = "#{App.name} - API Error: #{error['message']}"
  end

  def update_interface_last_updated sender
    last_check = Scheduler.shared_scheduler.last_check_words
    @status_item.toolTip = "#{App.name} - #{last_check}"
    @last_check_item.setTitle(last_check << ".")
  end

  def network_reachable
    FXReachability.sharedInstance.status > 0
  end

  def network_status_changed(status)
    if FXReachability.isReachable
      NSLog("Network came online - #{Time.now}") if BW.debug?
      Scheduler.shared_scheduler.refresh_and_trigger
    else
      NSLog("Network is no longer reachable - #{Time.now}") if BW.debug?
      refresh
    end
  end

  # NSMenu Delegate
  def menu(menu, willHighlightItem:item)
    @highlighted_item.unhighlight unless @highlighted_item.nil? || !@highlighted_item.is_a?(HNItemViewController)
    if item.nil?
      @highlighted_item = nil
      return
    end

    @highlighted_item = @items.find{|i| i.tag == item.tag}
    @highlighted_item.highlight if @highlighted_item.is_a? HNItemViewController
  end

  def menuWillOpen(menu)
    NSLog("Opening the menu.") if BW.debug?
    @menu_open = true
  end

  def menuDidClose(menu)
    NSLog("Menu did close.") if BW.debug?
    @menu_open = false
  end

  def show_about(sender)
    Mixpanel.sharedInstance.track("Show About")
    app = NSApplication.sharedApplication
    app.activateIgnoringOtherApps(true)
    NSApp.orderFrontStandardAboutPanel(sender)
  end

end
