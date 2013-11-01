class HNItem
  PROPERTIES = [:id, :rank, :title, :link, :points, :submitter, :comments]
  PROPERTIES.each { |prop|
    attr_accessor prop
  }

  def initialize(attributes = {})
    attributes.each { |key, value|
      self.send("#{key}=", value) if PROPERTIES.member? key.to_sym
    }
  end

  def original_title
    @title
  end

  def title
    if App::Persistence[@link]
      "✓ #{@hnitem.original_title}"
    else
      @title
    end
  end

end
