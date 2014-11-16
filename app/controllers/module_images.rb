module ControllerImages
  def background_img
    @_background_img ||= NSImage.imageNamed('background')
  end

  def comments_img
    @_comments_img ||= NSImage.imageNamed('comments')
  end

  def votes_img
    @_votes_image ||= NSImage.imageNamed('upvotes_badge')
  end

  def ad_img
    @_ad_image ||= NSImage.imageNamed('ad')
  end

  # Yosemite Dark Mode

  def background_img_dark
    background_img
  end

  def comments_img_dark
    @_comments_img_dark ||= NSImage.imageNamed('comments_dark')
  end

  def votes_img_dark
    @_votes_img_dark ||= NSImage.imageNamed('upvotes_badge_dark')
  end

  def ad_img_dark
    @_ad_img_dark ||= NSImage.imageNamed('ad_dark')
  end
end
