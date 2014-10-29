class MainMenu < MenuMotion::Menu
  include ActionRows
  include NewsRows

  attr_accessor :news, :controllers, :highlighted_item

  def init
    build_menu

    @hn_items ||= {}

    self.delegate = self
    self
  end

  def build_data_menu
    sections = []
    sections += news_sections
    sections += action_sections

    @menu_built = true

    build_menu_from_params(self, { sections: sections })
  end

  def build_menu
    HackerBase.shared.firebase['topstories'].on(:value) do |top_items|
      App::Persistence['last_update'] = Time.now.to_i

      # Get the first 30 top ids
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

  def item_exists?(id)
    @hn_items.keys.include?(id)
  end

  # NSMenuDelegate methods
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

  def menuWillOpen(menu)
    update_last_loaded
  end

end
