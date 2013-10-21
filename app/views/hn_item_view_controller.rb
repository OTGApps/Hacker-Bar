class HNItemViewController < NSViewController
  extend IB

  outlet :votes_image, NSImageView
  outlet :comments_image, NSImageView
  outlet :title_textfield, NSTextField

	attr_accessor :item

  # def initialize(item)
  #   @item = item
  # end

  def loadView
  	ap "view loaded with title: #{@item.original_title}"
  	# @title_textfield.setStringValue @item.original_title
  end

end
