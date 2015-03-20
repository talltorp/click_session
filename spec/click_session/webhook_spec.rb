require "spec_helper"

describe ClickSession::Webhook do
  describe "#call" do
    let(:url) { "http://test.unit/success" }

    let(:message) {
      {
        token: "abc",
        id: "cde",
      }
    }

    describe "when successful" do
      before(:each) do
        stub_request(:post, "http://test.unit/success").
         with(:body => '{"token":"abc","id":"cde"}',
              :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'26', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})
      end

      it "it sends the message to the url" do
        webhook = ClickSession::Webhook.new(url)

        webhook.call(message)

        assert_requested :post, url,
          {
            body: '{"token":"abc","id":"cde"}',
            times: 1
          }
      end

      it "sends the request as json" do
        webhook = ClickSession::Webhook.new(url)

        webhook.call(message)

        assert_requested :post, url,
          {
            headers: {
              'Content-Type' => 'application/json',
              'Accept' => 'application/json',
            },
            times: 1
          }
      end
    end

    describe "when there is a timeout" do
      it "raises an error" do
        stub_request(:post, "http://test.unit/success").
          with(:body => '{"token":"abc","id":"cde"}',
              :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'26', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
          to_timeout

        webhook = ClickSession::Webhook.new(url)

        expect{ webhook.call(message) }.to raise_error
      end
    end

    describe "when the response has a HTTP error code" do
      it "raises an error" do
        stub_request(:post, "http://test.unit/success").
          with(:body => '{"token":"abc","id":"cde"}',
              :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'26', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
          to_return(:status => 503, :body => "", :headers => {})
        webhook = ClickSession::Webhook.new(url)

        expect{ webhook.call(message) }.to raise_error
      end
    end
  end
end