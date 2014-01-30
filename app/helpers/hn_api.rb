class HNAPI

  # API_URL = "http://localhost:3000/hn/"
  API_URL = "http://www.hackerbarapp.com/"
  API_KEY = "2659a3fd-2f13-40ed-86ca-b7a40692979c"

  def self.get_news(&block)

    client = AFMotion::Client.build(API_URL) do
      header "Accept", "application/com.mohawkapps.hacker-bar; version=1"
      response_serializer :json
    end

    client.get("api", api_key:API_KEY) do |result|
      json = nil
      error = nil

      ap result

      if result.success?
        json = result.object
      else
        error = result
      end

      block.call json, error
    end

  end

end
