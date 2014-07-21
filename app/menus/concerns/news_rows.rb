module NewsRows

  def news_rows
    @controllers = []
    @news.map do |item|
      news_item = HNItemViewController.alloc.initWithNibName("HNItemViewController", bundle:nil)
      news_item.hnitem = item
      @controllers << news_item

      {
        title: item.title,
        view: news_item.view,
        tag: item.rank.to_s,
        target: self,
        action: :blank_action,
      }
    end
  end

  def news_sections
    [{
      rows: news_rows
    }]
  end

  def blank_action
    # This doesn't do anything but enable the view to be interactable
  end

end
