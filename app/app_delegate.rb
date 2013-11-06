class AppDelegate
  attr_accessor :menu, :items

  def applicationDidFinishLaunching(notification)
    @app_name = NSBundle.mainBundle.infoDictionary['CFBundleDisplayName']

    @menu = NSMenu.new
    @menu.setAutoenablesItems(false)
    @menu.delegate = self

    @items = []
    App::Persistence['check_interval'] ||= 120 # In seconds
    App::Persistence['launch_on_start'] ||= false
    App::Persistence['asked_to_launch_on_start'] ||= false

    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength(NSVariableStatusItemLength).init
    @status_item.menu = @menu
    @status_item.highlightMode = true
    @status_item.toolTip = @app_name
    reset_image

    update_menu

    # Scheduler.shared_scheduler.start_polling
    NSWorkspace.sharedWorkspace.notificationCenter.addObserver(Scheduler.shared_scheduler, selector:"restart_polling", name:NSWorkspaceDidWakeNotification, object:nil)
    NSWorkspace.sharedWorkspace.notificationCenter.addObserver(Scheduler.shared_scheduler, selector:"stop_polling", name:NSWorkspaceWillSleepNotification, object:nil)

    if App::Persistence['asked_to_launch_on_start'] == false
      App::Persistence['asked_to_launch_on_start'] = true
      # Ask the user to launch the app on start.
    end

  end

  def applicationWillTerminate(notification)
    Scheduler.shared_scheduler.stop_polling
  end

  def applicationWillBecomeActive(notification)
    # Start the timer
    Scheduler.shared_scheduler.refresh_and_start_polling
  end

  def update_menu
    @menu.removeAllItems

    @items.each do |news_item|
      tag = news_item.hnitem.id || rand(-999)
      @menu.addItem create_item(object:news_item, tag:tag.to_i)
    end

    @menu.addItem NSMenuItem.separatorItem
    @menu.addItem create_item(title: "Preferences:", enabled: false)
    @menu.addItem create_item(title: " Launch #{App.name} on login", action: "toggle_autolaunch:", checked: App::Persistence['launch_on_start'])
    @menu.addItem create_refresh_option_menu
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
    items << create_item(title: " Refresh Now", action:'refresh', image: 'refresh')
    items << NSMenuItem.separatorItem
    [
      [' Never', 0],
      [' 2 minutes', 120],
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

    # TODO: Get this to auto-update when the menu is open.
    # unless App::Persistence['last_check'].nil?
    #   last_check = Time.at(App::Persistence['last_check'].to_i)
    #   last_check_words = last_check.distanceOfTimeInWords

    #   items << NSMenuItem.separatorItem
    #   items << create_item(title: " Last Check: #{last_check_words}", enabled: false)
    # end

    items
  end

  def update_fetch_time sender
    NSLog "Updating fetch time to #{sender.tag}"
    time = sender.tag.to_i

    App::Persistence['check_interval'] = time

    if time > 0
      Scheduler.shared_scheduler.refresh_and_start_polling
    else
      Scheduler.shared_scheduler.stop_polling
    end

    # Rebuild the interface
    @sub_options.removeAllItems
    refresh_menu_options.each do |option|
      @sub_options.addItem option
    end
  end

  def refresh
    ap "refreshing the menu"
    @menu.itemArray.each do |item|
      break if item.isSeparatorItem
      item.setEnabled(false)
    end

    fetch
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
      if args[:image] == 'check'
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
  def start_animating
    @currentFrame = 0
    @stopping = false
    @animTimer = NSTimer.scheduledTimerWithTimeInterval(1.0/8.0, target:self, selector:"update_image:", userInfo:nil, repeats:true)
  end

  def stop_animating
    # This little trick will make sure that the spinner goes around at least once.
    @stopping = true
    if @animTimer && @stopping && @currentFrame == 0
      @animTimer.invalidate
      @animTimer = nil
      reset_image
    end
  end

  def update_image(timer)
    # get the image for the current frame
    image = "StatusAnimating_#{@currentFrame}".image
    @status_item.setImage(image)
    if @currentFrame == 7
      @currentFrame = 0
    else
      @currentFrame += 1
    end
    stop_animating if @stopping
  end

  def reset_image
    @status_item.image = "Status".image
    @status_item.alternateImage = "StatusHighlighted".image
  end

  # NSMenu Delegate
  def menu(menu, willHighlightItem:item)
    @items.each{|i| i.unhighlight}
    return if item.nil? || item.tag < 10
    @items.select{|i| i.tag == item.tag}.first.highlight
  end

  def blank_action(sender)
    # Whatever
  end

  def toggle_autolaunch sender
    autolaunch = !App::Persistence['launch_on_start']
    App::Persistence['launch_on_start'] = autolaunch
    ap "autolaunch: #{autolaunch}"
    start_at_login autolaunch
    sender.setState (autolaunch == true) ? NSOnState : NSOffState
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
        NSLog("Failed to start Helper")
        return
    end

  end

  private
  # Don't ever call this method directly. Use the refresh method
  def fetch
    start_animating
    ap "Fetching"
    HNAPI.get_news do |json, error|
      if error.nil? && json.count > 0
        @items = [] # Clear out the item array

        json['submissions'].each do |news|
          news_item = HNItemViewController.alloc.initWithNibName("HNItemViewController", bundle:nil)
          news_item.hnitem = HNItem.new(news)
          @items << news_item
        end
        App::Persistence['last_check'] = Time.now.to_i
        stop_animating
        update_menu
      else
        # TODO Handle this.
      end
    end
  end


end
