class AppDelegate
  attr_accessor :status_item, :menu, :items, :server_data_age

  def applicationDidFinishLaunching(notification)

    BubbleWrap.debug = true unless NSBundle.mainBundle.objectForInfoDictionaryKey('AppStoreRelease') == true

    @menu = NSMenu.new
    @menu.setAutoenablesItems(false)
    @menu.delegate = self

    @items = []
    App::Persistence['check_interval'] ||= 300 # In seconds
    App::Persistence['launch_on_login'] ||= false
    App::Persistence['clicked'] ||= []

    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength(NSSquareStatusItemLength).retain
    @status_item.menu = @menu
    @status_item.highlightMode = true
    @status_item.toolTip = App.name
    reset_image

    update_menu

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

    invocation = NSInvocation.invocationWithMethodSignature(self.methodSignatureForSelector("update_interface_last_updated:"))
    invocation.setTarget(self)
    invocation.setSelector("update_interface_last_updated:")
    NSRunLoop.mainRunLoop.addTimer(NSTimer.timerWithTimeInterval(5, invocation:invocation, repeats:true), forMode:NSRunLoopCommonModes)

    NSNotificationCenter.defaultCenter.addObserver(Scheduler.shared_scheduler, selector:"trigger_wait", name:NSWorkspaceDidWakeNotification, object:nil)
    NSNotificationCenter.defaultCenter.addObserver(Scheduler.shared_scheduler, selector:"stop_waiting", name:NSWorkspaceWillSleepNotification, object:nil)
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"network_status_changed:", name:FXReachabilityStatusDidChangeNotification, object:nil)

    GATracker.shared_tracker.track({event:"app", action:"launched"})
  end

  def applicationWillTerminate(notification)
    Scheduler.shared_scheduler.stop_waiting
    GATracker.shared_tracker.track({event:"app", action:"terminated"})
  end

  def applicationWillBecomeActive(notification)
    # Start the timer
    # Scheduler.shared_scheduler.refresh_and_trigger
    GATracker.shared_tracker.track({event:"app", action:"becameActive"})
  end

  def update_menu
    @menu.removeAllItems

    @items.each do |news_item|
      tag = news_item.hnitem.id || rand(-999)
      @menu.addItem create_item(object:news_item, tag:tag.to_i)
    end
    add_bottom_menu_items
  end

  def add_bottom_menu_items
    @menu.addItem NSMenuItem.separatorItem
    @menu.addItem create_item(title: "Preferences:", enabled: false)
    @menu.addItem create_item(title: " Launch #{App.name} on login", action: "toggle_autolaunch:", checked: App::Persistence['launch_on_login'])
    @menu.addItem create_refresh_option_menu

    # Auto-updating last check menu item
    @menu.addItem NSMenuItem.separatorItem
    @last_check_item ||= create_item(title: " " << Scheduler.shared_scheduler.last_check, enabled: false)
    @menu.addItem @last_check_item

    @menu.addItem NSMenuItem.separatorItem
    @menu.addItem create_item(title: "Quit", action:'terminate:')
  end

  def create_refresh_option_menu
    refresh_options = NSMenuItem.alloc.init
    refresh_options.setTitle(" Refresh Options")
    @sub_options ||= NSMenu.alloc.init
    @sub_options.removeAllItems

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
      option = NSMenuItem.alloc.initWithTitle(value[0], action:"update_fetch_time:" , keyEquivalent: '')
      option.tag = value[1]

      option.setState (option.tag == App::Persistence['check_interval']) ? NSOnState : NSOffState
      option.setEnabled true
      items << option
    end

    items
  end

  def update_fetch_time sender
    NSLog "Updating fetch time to #{sender.tag}"
    time = sender.tag.to_i

    App::Persistence['check_interval'] = time

    if time > 0
      Scheduler.shared_scheduler.refresh_and_trigger
    end

    # Rebuild the interface
    @sub_options.removeAllItems
    refresh_menu_options.each do |option|
      @sub_options.addItem option
    end
    GATracker.shared_tracker.track({event:"prefs", action:"updateFetchTime", value:time})
  end

  def refresh
    ap "Refreshing the menu" if BubbleWrap.debug?

    if network_reachable
      fetch
    else
      Scheduler.shared_scheduler.stop_waiting
      @menu.removeAllItems
      @menu.addItem create_item(title: "Network is offline.", enabled: false)
      add_bottom_menu_items
    end
  end

  def create_item(args={})
    args = {
      key:'',
      action: 'blank_action:',
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
        item.setState NSOnState
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
  # to stop animating, set the instance variable @animation_stopped to true
  def animate_icon
    ap "Starting image animation" if BubbleWrap.debug?
    @current_frame = 0

    icon_animation_timer = EM.add_periodic_timer 1.0/8.0 do
      # get the image for the current frame
      image = "StatusAnimating_#{@current_frame}".image
      @status_item.setImage(image)
      if @current_frame == 7
        @current_frame = 0
      else
        @current_frame = @current_frame + 1
      end

      if @animation_stopped == true
        ap "Stopping image animation" if BubbleWrap.debug?
        EM.cancel_timer(icon_animation_timer)
        @animation_stopped = nil
        reset_image
      end
    end
  end

  def reset_image
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
    GATracker.shared_tracker.track({event:"prefs", action:"autolaunch", value:autolaunch})
  end

  # TODO: Get this working properly.
  def start_at_login enabled
    url = NSBundle.mainBundle.bundleURL.URLByAppendingPathComponent("Contents/Library/LoginItems/HackerBarLauncher.app", isDirectory:true)

    status = LSRegisterURL(url, true)
    unless status
        NSLog("Failed to LSRegisterURL '%@': %jd", url, status)
        return
    end

    success = SMLoginItemSetEnabled("com.mohawkapps.hackerbarlauncher", enabled)
    unless success
      GATracker.shared_tracker.track({event:"prefs", action:"autolaunch", label:"failed"})
      NSLog("Failed to start #{App.name} launch helper.")
      return
    end
  end

  private
  # Don't ever call this method directly. Use the refresh method
  def fetch
    animate_icon
    ap "Fetching new data" if BubbleWrap.debug?
    HNAPI.get_news do |json, error|
      if error.nil? && json.count > 0
        GATracker.shared_tracker.track({event:"api", action:"hit"})

        json['submissions'].each_with_index do |news, i|
          if @items[i].nil?
            news_item = HNItemViewController.alloc.initWithNibName("HNItemViewController", bundle:nil)
            news_item.hnitem = HNItem.new(news)
            @items[i] = news_item
          else
            @items[i].hnitem = HNItem.new(news)
          end
        end
        @server_data_age = json['updated_words'] || nil
        App::Persistence['last_check'] = Time.now.to_i
        update_interface_last_updated nil
        update_menu
      else
        NSLog("Error: Could not get data from API")
        GATracker.shared_tracker.track({event:"api", action:"error"})
      end
      @animation_stopped = true
      Scheduler.shared_scheduler.trigger_wait
    end
  end

  def update_interface_last_updated sender
    if @server_data_age.nil?
      last_check = Scheduler.shared_scheduler.last_check
      @status_item.toolTip = "#{App.name} - #{last_check}"
      @last_check_item.setTitle(last_check << ".")
    else
      @status_item.toolTip = "#{App.name} - Updated: #{@server_data_age}"
      @last_check_item.setTitle("Data Cache Age: " << @server_data_age << ".")
    end
  end

  def network_reachable
    FXReachability.sharedInstance.status > 0
  end

  def network_status_changed(status)
    if FXReachability.isReachable
      ap "Network came online." if BubbleWrap.debug?
      Scheduler.shared_scheduler.refresh_and_trigger
    end
  end

  # NSMenu Delegate
  def menu(menu, willHighlightItem:item)
    @items.each{|i| i.unhighlight}
    return if item.nil? || item.tag < 10
    @items.select{|i| i.tag == item.tag}.first.highlight
  end

  def menuWillOpen(menu)
    @items.each{|i| i.unhighlight if i.is_a? HNItemViewController}
  end

end
