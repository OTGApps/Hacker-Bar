class HNItemViewController < NSViewController
  extend IB
  include BW::KVO

  outlet :votes_count, NSTextField
  outlet :votes_image, NSImageView
  outlet :headline, NSTextField
  outlet :comment_count, NSTextField
  outlet :comment_image, NSImageView
  outlet :background_image, NSImageView

  attr_accessor :hnitem, :view_loaded

  def loadView
    viewWillLoad
    super
    viewDidLoad
  end

  def viewWillLoad
  end

  def viewDidLoad
    set_interface
    @view_loaded = true
  end

  def hnitem=(hn)
    @hnitem = hn
    set_interface if @view_loaded

    observe(@hnitem, :version) do |old_value, new_value|
      mp "Updating item's interface: #{@hnitem.id}"
      set_interface
    end
  end

  def tag
    @tag ||= @hnitem.id.to_s.to_sym
  end

  def hide(should_i)
    @comment_count.hidden = should_i
    @votes_count.hidden = should_i
    @comment_image.hidden = should_i
  end

  def set_interface
    @headline.setStringValue @hnitem.title

    if @hnitem.comments == "yc_advertisement"
      hide(true)
      @votes_image.setImage(NSImage.imageNamed('ad'))
    else
      hide(false)
      @votes_image.setImage(NSImage.imageNamed('UpvotesBadge'))

      comment_count = @hnitem.comments || 0
      votes_count =   @hnitem.score.to_i || 0

      comment_count = SI.convert(comment_count) if comment_count > 1000
      votes_count =   SI.convert(votes_count) if   votes_count > 1000

      @comment_count.setStringValue comment_count
      @votes_count.setStringValue votes_count
    end

  end

  def clicked_link(sender)
    NSLog "Clicked Item: #{@hnitem.link}, #{@hnitem.id}" if BW.debug?

    # Log that the user went to that site.
    App::Persistence['clicked'] =  App::Persistence['clicked'].mutableCopy << @hnitem.id if @hnitem.id
    Mixpanel.sharedInstance.track("Link Click", properties:{link:@hnitem.link, id:@hnitem.id}) unless BW.debug?

    launch_link
  end

  def clicked_comments(sender)
    NSLog "Clicked Comments: #{@hnitem.comments_url}" if BW.debug?
    Mixpanel.sharedInstance.track("Comment Click", properties:{link:@hnitem.comments_url}) unless BW.debug?
    launch_comments
  end

  def highlight
    # NSLog "Highlighting: #{@hnitem.title}" if BW.debug?
    @headline.setTextColor NSColor.highlightColor
    @background_image.setImage(background_image)
    view.setNeedsDisplay true
  end

  def unhighlight
    # NSLog "Unhighlighting: #{@hnitem.title}" if BW.debug?
    return if @background_image.image.nil?
    @headline.setTextColor NSColor.controlTextColor
    @background_image.setImage nil
    view.setNeedsDisplay true
  end

  def background_image
    @cached_background_image ||= NSImage.imageNamed("background")
  end

  def launch_link
    launch_browser @hnitem.link
  end

  def launch_comments
    launch_browser @hnitem.comments_url
  end

  def launch_browser(url)
    # unhighlight
    # App.delegate.menu.cancelTracking # This will auto-close the menu (v2 feature)

    url = NSURL.URLWithString(url)
    if NSWorkspace.sharedWorkspace.openURL(url)
      @headline.setStringValue @hnitem.title

      # mi = @menu.itemWithTag(sender.tag)
      # mi.setTitle(@items[sender.tag].title)
      # @menu.itemChanged(mi)
    else
      # TODO: Make this more betterer
      NSLog("Failed to open url: %@", url.description)
    end
  end

  def viewDidUnload
   self.releaseAllViews
 end

end
