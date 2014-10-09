class HackerBase
  HACKER_NEWS = 'https://hacker-news.firebaseio.com/v0/'

  def self.shared
    Dispatch.once { @shared = self.new }
    @shared
  end

  def firebase
    @firebase ||= Firebase.new(HACKER_NEWS)
  end

end
