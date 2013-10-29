class HNItemViewController < NSViewController
  extend IB

  outlet :votes_count, NSTextField
  outlet :votes_image, NSImageView
  outlet :headline, NSTextField
  outlet :comment_count, NSTextField
  outlet :comment_image, NSImageView

	attr_accessor :item

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
    @headline.setStringValue @item.original_title
    @comment_count.setStringValue( @item.comments['count'] || 0 )
    @votes_count.setStringValue( @item.points || 0 )
  end

end
