class MainMenu < MenuMotion::Menu
  include ActionRows
  include NewsRows

  attr_accessor :news, :controllers, :highlighted_item

  def init
    add_observers
    build_menu
    start_last_loaded_timer

    @hn_items ||= {}

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

    @menu_built = true

    build_menu_from_params(self, { sections: sections })
  end

  def item_exists?(id)
    @hn_items.keys.include?(id)
  end

  def build_menu
    HackerBase.shared.firebase['topstories'].on(:value) do |top_items|
      App::Persistence['last_update'] = Time.now.to_i

      # Get the forst 30 top ids
      @hn_ids = top_items.value.first(30)

      # Add an HNItem to the items array
      @hn_ids.each do |id|
        @hn_items[id] = HNItem.new(id) unless item_exists?(id)
      end

      # Remove items that no longer exist in the top 30
      @hn_items.reject!{ |k,v| !@hn_ids.include?(k) }

      # Populate the news array
      @news = @hn_ids.map{ |id|
        @hn_items.values.find{ |v| v.id == id }
      }

      #Build the menu
      build_data_menu unless @menu_built
    end
  end

  def build_menu_from_params(root_menu, params)
    self.removeAllItems
    super
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

  # Sleep / Wake Ovservers

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
    @last_update_timer.invalidate unless @last_update_timer.nil?
    @last_update_timer = nil
  end

  def waking_up(notification)
    start_last_loaded_timer
  end

end
