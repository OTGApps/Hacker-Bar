class MainMenu < MenuMotion::Menu
  include ActionRows
  include NewsRows

  attr_accessor :news, :controllers, :highlighted_item

  def init
    add_observers
    start_update_timer
    start_last_loaded_timer
    self.delegate = self
    self
  end

  def build_error_menu(message = 'Unknown Error')
    NSApplication.sharedApplication.delegate.update_status_item('StatusError')
    sections = []
    sections += [{
      rows: [{
        title: "Error Retrieving data from YCombinator"
      },{
        title: message
      }]
    }]
    sections += action_sections

    build_menu_from_params(self, { sections: sections })
  end

  def build_data_menu
    sections = []
    sections += news_sections
    sections += action_sections

    build_menu_from_params(self, { sections: sections })
  end

  def build_menu
    # Make the API Call
    NSApplication.sharedApplication.delegate.update_status_item('StatusLoading')
    HNAPI.sharedAPI.get_news do |parsed, error|
      App::Persistence['last_check'] = Time.now.to_i

      @news = []
      if error.nil?
        parsed.each do |i, news|
          @news << HNItem.new(news)
        end

        build_data_menu
      else
        NSLog("Error: Could not get data from API")
        error_string = "Error: #{error.localizedDescription}"

        # Start checking more often til the internet connection comes back online.
        if !@update_timer.nil? && @update_timer.timeInterval > 100
          @update_timer.invalidate
          @update_timer = nil
          start_update_timer(30)
        end

        build_error_menu(error_string)
      end

      NSApplication.sharedApplication.delegate.update_status_item
    end
  end

  def build_menu_and_reset
    build_menu
    start_update_timer
  end

  def build_menu_from_params(root_menu, params)
    self.removeAllItems
    super
  end

  def start_update_timer(seconds = nil)
    unless @update_timer.nil? # Invalidate the current timer.
      @update_timer.invalidate
      @update_timer = nil
    end

    if seconds.nil?
      @update_timer = NSTimer.scheduledTimerWithTimeInterval(App::Persistence['check_interval'], target: self, selector: "build_menu", userInfo: nil, repeats: true)
      @update_timer.setTolerance(10)
      @update_timer.fire
    else
      @update_timer = NSTimer.scheduledTimerWithTimeInterval(seconds, target: self, selector: "build_menu_and_reset", userInfo: nil, repeats: false)
      @update_timer.setTolerance(10)
    end
  end

  def start_last_loaded_timer
    unless @last_update_timer.nil? # Invalidate the current timer.
      @last_update_timer.invalidate
      @last_update_timer = nil
    end

    @last_update_timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "update_last_loaded", userInfo: nil, repeats: true)
    @last_update_timer.setTolerance(10)
    @last_update_timer.fire
  end

  def menu(menu, willHighlightItem:item)
    @highlighted_item.unhighlight unless @highlighted_item.nil?

    if item.nil? || item.tag.nil?
      # We're hovering over a regular menu item here.
      @highlighted_item = nil
      return
    end

    @highlighted_item = @controllers.find{|i| i.tag == item.tag}
    @highlighted_item.highlight if @highlighted_item.is_a? HNItemViewController
  end

  def add_observers
    @sleep_observer ||= NSWorkspace.sharedWorkspace.notificationCenter.addObserver(self, selector:'going_to_sleep:', name:NSWorkspaceWillSleepNotification, object:nil)
    @wake_observer ||= NSWorkspace.sharedWorkspace.notificationCenter.addObserver(self, selector:'waking_up:', name:NSWorkspaceDidWakeNotification, object:nil)
  end

  def remove_observers
    NSWorkspace.sharedWorkspace.notificationCenter.removeObserver(@sleep_observer)
    NSWorkspace.sharedWorkspace.notificationCenter.removeObserver(@wake_observer)
    @sleep_observer = nil
    @wake_observer = nil
  end

  def going_to_sleep(notification)
    @update_timer.invalidate unless @update_timer.nil?
    @update_timer = nil

    @last_update_timer.invalidate unless @last_update_timer.nil?
    @last_update_timer = nil
  end

  def waking_up(notification)
    start_update_timer
    start_last_loaded_timer
  end

end
