class NSColor
  def invert
    color = (colorSpaceName == "NSNamedColorSpace") ? self.colorUsingColorSpace(NSColorSpace.genericRGBColorSpace) : self

    r = 1.0 - color.red
    g = 1.0 - color.green
    b = 1.0 - color.blue
    a = color.alpha
    NSColor.colorWithRed(r, green: g, blue: b, alpha: a)
  end

  def red
    redComponent
  rescue NSInvalidArgumentException
    whiteComponent
  rescue Exception
    nil
  end

  def green
    greenComponent
  rescue NSInvalidArgumentException
    whiteComponent
  rescue Exception
    nil
  end

  def blue
    blueComponent
  rescue NSInvalidArgumentException
    whiteComponent
  rescue Exception
    nil
  end

  def alpha
    alphaComponent
  rescue Exception
    nil
  end

end
