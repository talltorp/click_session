require "rest-client"

module ClickSession
  class Webhook
    def initialize(url)
      @url = url
    end

    def call(message)
      RestClient.post(
        url,
        message.to_json,
        {
          content_type: :json,
          accept: :json,
        }
      )
    end

    private

    attr_reader :url
  end
end