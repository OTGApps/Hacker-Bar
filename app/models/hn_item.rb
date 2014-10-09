class HNItem
  PROPERTIES = [:version, :id, :type, :score, :title, :url, :points, :by, :kids]
  PROPERTIES.each { |prop|
    attr_accessor prop
  }

  def initialize(id)
    @id = id
    @type = nil
    @score = 0
    @points = 0
    @version = 0
    @title = 'Loading...'
    @url = ''
    @by = ''
    @kids = []

    HackerBase.shared.firebase['item'][id.to_s].on(:value) do |item|
      update(item)
    end
  end

  def update(data)
    PROPERTIES.each { |prop|
      self.send("#{prop}=", data.value[prop]) if data.value[prop]
    }
    self.version = self.version + 1
  end

  def comments
    kids.count
  end

  def comments_url
    "https://news.ycombinator.com/item?id=#{id}"
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

  def to_s
    s = ""
    PROPERTIES.each { |prop|
      s << "#{prop}: #{self.send(prop)}\n"
    }
    s
  end

end
