class HNAPI

  # APIURL = "http://localhost:3000/hn/"
  APIURL = "http://www.hackerbarapp.com/api/"

  def self.get_news(&block)

    params = {
      api_key: "2659a3fd-2f13-40ed-86ca-b7a40692979c"
    }

    headers = {
      accept: "application/com.mohawkapps.hacker-bar; version=1"
    }

    options = {
      payload: params,
      headers: headers,
    }

    BW::HTTP.get(APIURL, options) do |response|
        json = nil
        error = nil

        if response.ok?
          json = BW::JSON.parse(response.body.to_str)
        else
          error = BW::JSON.parse(response.body.to_str)
        end

        block.call json, error
    end
  end

end
