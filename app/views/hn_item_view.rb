class HNItemView < NSView
  # extend IB

  # outlet :votes_image, NSImageView
  # outlet :comments_image, NSImageView
  # outlet :title_textfield, NSTextField

  PADDING_X = 2
  PADDING_y = 1

	attr_accessor :item, :votes_image

	def initWithFrame(viewRect)
		super
		# ap "init"
		self
	end

  # def initWithNibName(name, bundle: bundle)
  #   super
  #   self
  # end


	# def setPostsFrameChangedNotifications(notification)
	# 	ap "WHAAA?"
	# 	ap notification
	# end

	def drawRect(dirtyRect)
    ap "calling drawrect"
    ap self.bounds

    fullBounds = self.bounds
    # fullBounds.size.height += 4
    NSBezierPath.bezierPathWithRect(fullBounds).setClip

 #    # Then do your drawing, for example...
    # NSColor.blueColor.set
    # NSRectFill(fullBounds)

    "UpvotesBadge".image.drawAtPoint(NSMakePoint(PADDING_X, PADDING_y), fromRect:NSZeroRect, operation:NSCompositeSourceOver, fraction:1)

		white_text_attributes = {
			NSForegroundColorAttributeName => NSColor.whiteColor,
			NSFontAttributeName => NSFont.systemFontOfSize(10)
		}

		points = @item.points.to_s
		points_size = points.sizeWithAttributes(white_text_attributes)
		points_text_point = NSMakePoint(PADDING_X, 0)
		points.drawAtPoint(points_text_point, withAttributes:white_text_attributes)

		text_attributes = {
			NSForegroundColorAttributeName => NSColor.textColor,
			NSFontAttributeName => NSFont.systemFontOfSize(12)
		}

		title = @item.original_title
		title_size = title.sizeWithAttributes(text_attributes)
		title_text_point = NSMakePoint(24 + (PADDING_X * 3), PADDING_y)
		title.drawAtPoint(title_text_point, withAttributes:text_attributes)

  #   self.lockFocus
		# img_url = NSURL.fileURLWithPath(File.join(NSBundle.mainBundle.resourcePath, 'Status.png'))
		# img = CIImage.imageWithContentsOfURL(img_url)
		# imgSize = CGSizeMake(16,16)
		# srcRect = NSMakeRect( 0.0, 0.0, imgSize.width, imgSize.height )
  #   img.drawInRect(srcRect, fromRect:dirtyRect, operation:NSCompositeSourceOver, fraction:1.0)
  #   self.unlockFocus

 #    ap @item.title
  end

end
