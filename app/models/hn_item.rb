class HNItem
  PROPERTIES = [:rank, :title, :link, :points, :submitter, :comments]
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
  	t = ""
  	t << "✓ " if App::Persistence[@link]
  	t << "(#{@points}/#{@comments['count']}) #{@title}"
  	t
  end
end
