class AppDelegate
  attr_accessor :menu, :items

  def applicationDidFinishLaunching(notification)
    @app_name = NSBundle.mainBundle.infoDictionary['CFBundleDisplayName']

    @menu = NSMenu.new

    @items = []
    App::Persistence['check_interval'] ||= 60 # In seconds

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

  def update_menu
    stop_animating
    @menu.removeAllItems

    @items.each_with_index do |item, tag|
      @menu.addItem create_item(item.title, "launch_hn:", tag)
    end

    @menu.addItem separator
    @menu.addItem create_item("Manual Refresh", 'refresh')
    @menu.addItem separator
    @menu.addItem create_item("Quit", 'terminate:')
  end

  def fetch
    i = []
    ap "Fetching news"
    start_animating
    HNAPI.get_news do |json, error|
      if error.nil? && json.count > 0
        @items = [] # Clear out the item array

        json['submissions'].each do |news|
          news_item = HNItem.new(news)
          @items << news_item
        end
        ap "Got news"
        update_menu
      else
        # Handle this.
      end
    end
  end

  def refresh
    @menu.itemArray.each do |item|
      break if item.isSeparatorItem
      item.setEnabled(false)
    end

    fetch
    # @status_item.popUpStatusItemMenu(@menu) # This immediately reopens the menu
  end

  def launch_hn(sender)
    url_string = @items[sender.tag].link
    url = NSURL.URLWithString(url_string)
    if NSWorkspace.sharedWorkspace.openURL(url)
      # Log that the user went to that site.
      App::Persistence[@items[sender.tag].link] = true

      mi = @menu.itemWithTag(sender.tag)
      mi.setTitle(@items[sender.tag].title)
      @menu.itemChanged(mi)
    else
      # TODO: Make this more betterer
      NSLog("Failed to open url: %@", url.description)
    end
  end

  def create_item(name, action, tag = nil)
    item = NSMenuItem.alloc.initWithTitle(name, action: action, keyEquivalent: '')
    item.tag = tag if tag
    item
  end

  def separator
    NSMenuItem.separatorItem
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

end
