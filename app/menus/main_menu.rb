class MainMenu < MenuMotion::Menu
  include ActionRows
  include NewsRows

  attr_accessor :news, :controllers, :highlighted_item

  def init
    start_update_timer
    self.delegate = self
    self
  end

  def build_error_menu(message = 'Unknown Error')
    sections = [{
      rows: [{
        title: "Error Retrieving data from YCombinator"
      },{
        title: message
      }]
    }]
    sections << action_sections

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
    HNAPI.sharedAPI.get_news do |parsed, error|
      App::Persistence['last_check'] = Time.now.to_i

      @news = []
      if error.nil? && parsed.count > 0
        parsed.each do |i, news|
          @news << HNItem.new(news)
        end

        build_data_menu
      else
        NSLog("Error: Could not get data from API")
        NSLog("API Error: #{error['error']['message']}") unless error['error'].nil?
        error_string = "Error: #{error.description}"

        build_error_menu(error_string)
      end

      NSApplication.sharedApplication.delegate.update_status_item
    end
  end

  def build_menu_from_params(root_menu, params)
    self.removeAllItems
    super
  end

  def start_update_timer
    @update_timer = NSTimer.scheduledTimerWithTimeInterval(App::Persistence['check_interval'], target: self, selector: "build_menu", userInfo: nil, repeats: true)
    @update_timer.setTolerance(10)
    @update_timer.fire
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
end
