class HNItemViewController < NSViewController
  extend IB

  outlet :votes_count, NSTextField
  outlet :votes_image, NSImageView
  outlet :headline, NSTextField
  outlet :comment_count, NSTextField
  outlet :comment_image, NSImageView
  outlet :background_image, NSImageView

	attr_accessor :hnitem, :tag, :view_loaded

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
  end

  def set_interface
    @headline.setStringValue @hnitem.title

    if @hnitem.submitter == "yc_advertisement"
      @comment_count.hidden = true
      @votes_count.hidden = true
      @comment_image.hidden = true
      @votes_image.setImage "ad".image
    else
      @comment_count.hidden = false
      @votes_count.hidden = false
      @comment_image.hidden = false
      @votes_image.setImage "UpvotesBadge".image

      comment_count = @hnitem.comments['count'].to_i || 0
      votes_count =   @hnitem.points.to_i || 0

      comment_count = SI.convert(comment_count) if comment_count > 1000
      votes_count =   SI.convert(votes_count) if   votes_count > 1000

      @comment_count.setStringValue comment_count
      @votes_count.setStringValue votes_count
    end

  end

  def clicked_link(sender)
    NSLog "Clicked Item: #{@hnitem.title}" if BW.debug?

    # Log that the user went to that site.
    App::Persistence['clicked'] =  App::Persistence['clicked'].mutableCopy << @hnitem.id if @hnitem.id

    launch_link
  end

  def clicked_comments(sender)
    NSLog "Clicked Comments: #{@hnitem.title}" if BW.debug?
    launch_comments
  end

  def highlight
    NSLog "Highlighting: #{@hnitem.title}" if BW.debug?
    @headline.setTextColor NSColor.highlightColor
    @background_image.setImage "background".image
    view.setNeedsDisplay true
  end

  def unhighlight
    NSLog "Unhighlighting: #{@hnitem.title}" if BW.debug?
    return if @background_image.image.nil?
    @headline.setTextColor NSColor.controlTextColor
    @background_image.setImage nil
    view.setNeedsDisplay true
  end

  def launch_link
    launch_browser @hnitem.link
  end

  def launch_comments
    launch_browser @hnitem.comments['url']
  end

  def launch_browser(url)
    # unhighlight
    # App.delegate.menu.cancelTracking # This will auto-close the menu (v2 feature)

    url = "https://news.ycombinator.com/" << url unless url.start_with? "http"
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
