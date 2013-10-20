class String
  def image
    NSImage.imageNamed(self)
  end

  # Why the flip doesn't this work?
  def trunc(length, options = {})
  	text = self.dup
  	options[:omission] ||= "..."

  	length_with_room_for_omission = length - options[:omission].length
  	chars = text.length
  	stop = options[:separator] ?
  	(chars.rindex(options[:separator].length, length_with_room_for_omission) || length_with_room_for_omission) : length_with_room_for_omission

		(chars.length > length ? chars[0...stop] + options[:omission] : text).to_s
  end

end
