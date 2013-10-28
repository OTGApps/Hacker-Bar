class HNItemViewController < NSWindowController
  extend IB

  outlet :votes_image, NSImageView
  outlet :comments_image, NSImageView
  outlet :headline, NSTextField

	attr_accessor :item

  # def initialize(item)
  #   @item = item
  # end

  # def loadView
  # 	ap "view loaded with title: #{@item.original_title}"
  # 	ap @headline
  #   # @headline.setStringValue @item.original_title
  # end

end
