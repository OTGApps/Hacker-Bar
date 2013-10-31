class HNItemViewController < NSViewController
  extend IB

  outlet :votes_count, NSTextField
  outlet :votes_image, NSImageView
  outlet :headline, NSTextField
  outlet :comment_count, NSTextField
  outlet :comment_image, NSImageView
  outlet :background_image, NSImageView

	attr_accessor :hnitem, :tag

  def loadView
    viewWillLoad
    super
    viewDidLoad
  end

  def viewWillLoad
  end

  def viewDidLoad
    set_interface
  end

  def set_interface
    # ap "#{@hnitem.points.to_i} = #{SI.convert( @hnitem.points.to_i )}"
    # ap "#{@hnitem.comments['count'].to_i} = #{SI.convert( @hnitem.comments['count'].to_i )}"
    @headline.setStringValue @hnitem.original_title
    @comment_count.setStringValue( SI.convert( @hnitem.comments['count'].to_i ) || 0 )
    @votes_count.setStringValue( SI.convert(@hnitem.points.to_i) || 0 )
  end

  def clicked_link(sender)
    ap "Clicked Item: #{@hnitem.original_title}"
    launch_link
  end

  def clicked_comments(sender)
    ap "Clicked Comments: #{@hnitem.original_title}"
    launch_comments
  end

  def highlight
    @headline.setTextColor NSColor.highlightColor
    @background_image.setImage "background".image
    view.setNeedsDisplay(true)
  end

  def unhighlight
    @headline.setTextColor NSColor.controlTextColor
    @background_image.setImage nil
    view.setNeedsDisplay(true)
  end

  def launch_link
    launch_browser @hnitem.link
  end

  def launch_comments
    launch_browser @hnitem.comments['url']
  end

  def launch_browser(url)
    unhighlight

    url = NSURL.URLWithString(url)
    if NSWorkspace.sharedWorkspace.openURL(url)
      # Log that the user went to that site.
      App::Persistence[@hnitem.link] = true

      # mi = @menu.itemWithTag(sender.tag)
      # mi.setTitle(@items[sender.tag].title)
      # @menu.itemChanged(mi)
    else
      # TODO: Make this more betterer
      NSLog("Failed to open url: %@", url.description)
    end
  end

end
