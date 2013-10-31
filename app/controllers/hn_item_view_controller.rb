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
    ap "#{@hnitem.points.to_i} = #{SI.convert( @hnitem.points.to_i )}"
    ap "#{@hnitem.comments['count'].to_i} = #{SI.convert( @hnitem.comments['count'].to_i )}"
    @headline.setStringValue @hnitem.original_title
    @comment_count.setStringValue( SI.convert( @hnitem.comments['count'].to_i ) || 0 )
    @votes_count.setStringValue( SI.convert(@hnitem.points.to_i) || 0 )
  end

  def highlight
    ap "highlighting #{self.tag}"
    @headline.setStringValue "WUT?"
    view.backgroundColor = NSColor.blueColor
    view.setNeedsDisplay(true)
  end

  def unhighlight
    @headline.setStringValue @hnitem.original_title
    view.backgroundColor = NSColor.whiteColor
    view.setNeedsDisplay(true)
  end

end
