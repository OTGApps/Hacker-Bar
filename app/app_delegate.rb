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
    App::Persistence['open_links_in_background'] ||= true

    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength(NSVariableStatusItemLength).init
    @status_item.menu = @menu
    @status_item.highlightMode = true
    @status_item.toolTip = @app_name
    reset_image

    update_menu
    fetch

    # Start the timer
    Scheduler.shared_scheduler.start_polling
  end

  def applicationWillTerminate(notification)
    Scheduler.shared_scheduler.stop_polling
  end

  def applicationWillResignActive(notification)
    Scheduler.shared_scheduler.stop_polling
    @animTimer.invalidate if @animTimer
  end

  def applicationWillBecomeActive(notification)
    Scheduler.shared_scheduler.start_polling
  end

  def update_menu
    stop_animating
    @menu.removeAllItems

    @items.each do |news_item|
      @menu.addItem create_item(object:news_item, tag:news_item.hnitem.id.to_f)
    end

    @menu.addItem NSMenuItem.separatorItem
    @menu.addItem create_item(title: "Preferences:", enabled: false)
    @menu.addItem create_item(title: " Launch on system start", checked: App::Persistence['launch_on_start'])
    @menu.addItem create_item(title: " Open links in background", checked: App::Persistence['open_links_in_background'])
    @menu.addItem NSMenuItem.separatorItem
    @menu.addItem create_item(title: " Refresh", action:'refresh', image: 'refresh')
    @menu.addItem NSMenuItem.separatorItem
    @menu.addItem create_item(title: "Quit", action:'terminate:')
  end

  def fetch
    start_animating
    HNAPI.get_news do |json, error|
      if error.nil? && json.count > 0
        @items = [] # Clear out the item array

        json['submissions'].each do |news|
          news_item = HNItemViewController.alloc.initWithNibName("HNItemViewController", bundle:nil)
          news_item.hnitem = HNItem.new(news)
          @items << news_item
        end
        update_menu
      else
        # TODO Handle this.
      end
    end
  end

  def refresh
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
      i = args[:image].image
      item.setOffStateImage i
      item.setOnStateImage i
      item.onStateImage.setTemplate(true)
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

def start_at_login enabled
    url = NSBundle.mainBundle.bundleURL.URLByAppendingPathComponent("Contents/Library/LoginItems/ycmenu-app-launcher.app")
    LSRegisterURL(url, true)
    unless SMLoginItemSetEnabled("com.mohawkapps.ycmenu-app-launcher", enabled)
      NSLog "SMLoginItemSetEnabled failed!"
    end
  end

end
