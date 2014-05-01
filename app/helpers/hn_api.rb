class HNAPI

  HACKER_NEWS = 'https://news.ycombinator.com/'

  def self.sharedAPI
    Dispatch.once { @shared = self.new }
    @shared
  end

  def get_news(&block)
    ap 'Getting news' if BW.debug?
    AFMotion::HTTP.get(HACKER_NEWS) do |result|
      error = nil
      parsed = parse_hn(result.body)

      unless parsed.count == 30
       error = result
      end
      block.call parsed, error
    end
  end

  def parse_hn(html)
    document = ONOXMLDocument.HTMLDocumentWithString(html, encoding:NSUTF8StringEncoding, error:nil)

    news = {}

    id = 0
    document.enumerateElementsWithXPath("//td[@class='subtext']", block:-> element {
      # NSLog("%@: %@", element.tag, element.attributes)
      news[id] ||= {}
      news[id][:rank] = id

      score = element.firstChildWithTag("span")

      if !score.nil? && score.stringValue.include?('points')
        news[id][:points] = score.stringValue.split(' ').first

        # Submitter
        submitter = element.firstChildWithTag('a')
        if submitter.valueForAttribute('href').include?('user')
          submitter_handle = submitter.stringValue
          news[id][:submitters] = submitter.stringValue
        end

        # Comments
        comments = element.childrenWithTag('a').last
        if comments.valueForAttribute('href').include?('item')
          comments_path  = comments.valueForAttribute('href')
          comments_count = comments.stringValue.split(' ').first
          comments_url   = "https://news.ycombinator.com/#{comments_path}"
          news[id][:comments] = { url: comments_url, count: comments_count.to_i }

          news[id][:id] = comments_url.split('id=').last
        end

      else
        # It's an advertisement
        news[id][:score] = '0'
        news[id][:points] = '0'
        news[id][:submitters] = 'yc_advertisement'
        news[id][:comments] = 'yc_advertisement'
      end
      id = id + 1
    })

    # Get title and link
    id = 0
    document.enumerateElementsWithXPath("//td[@class='title']/a", block:-> element {
      next if id > 29

      news[id][:title] = element.stringValue.strip
      news[id][:link] = element.valueForAttribute('href')

      news[id][:link] = "https://news.ycombinator.com/#{news[id][:link]}" unless news[id][:link].start_with?('http')
      id = id + 1
    })

    news
  end
end
