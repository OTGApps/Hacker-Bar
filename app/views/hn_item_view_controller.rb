class HNItemViewController < NSViewController
  extend IB

  outlet :votes_count, NSTextField
  outlet :votes_image, NSImageView
  outlet :headline, NSTextField
  outlet :comment_count, NSTextField
  outlet :comment_image, NSImageView

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
    @headline.setStringValue @hnitem.original_title
    @comment_count.setStringValue( @hnitem.comments['count'] || 0 )
    @votes_count.setStringValue( @hnitem.points || 0 )
  end

  def highlight
    ap "highlighting #{self.tag}"
    view.backgroundColor = NSColor.blueColor
  end

  def unhighlight
    view.backgroundColor = NSColor.whiteColor
  end

end
