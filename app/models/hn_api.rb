class HNAPI

  # APIURL = "http://localhost:3000/hn/?version=v1"
  APIURL = "http://gertig.com/hn?version=v1"

  def self.get_news(&block)

    BW::HTTP.get(APIURL) do |response|
        json = nil
        error = nil

        if response.ok?
          json = BW::JSON.parse(response.body.to_str)
        else
          error = response.error_message
        end

        block.call json, error
    end
  end

end
