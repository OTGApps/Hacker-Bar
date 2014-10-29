class HackerBase
  def self.shared
    Dispatch.once { @shared = self.new }
    @shared
  end

  def firebase
    @firebase ||= Firebase.new('https://hacker-news.firebaseio.com/v0/')
  end
end
