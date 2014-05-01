class HNItem
  PROPERTIES = [:id, :rank, :title, :link, :points, :submitter, :comments]
  PROPERTIES.each { |prop|
    attr_accessor prop
  }

  def initialize(attributes = {})
    attributes.each { |key, value|
      self.send("#{key}=", value) if PROPERTIES.member? key
    }
  end

  def original_title
    @title
  end

  def title
    if App::Persistence['clicked'].include? @id
      "✓ #{@title}"
    else
      @title
    end
  end

  def ==(other_object)
    return true if other_object.id == @id
    false
  end

end
