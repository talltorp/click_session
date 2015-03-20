require 'spec_helper'
require 'click_session/configuration'
require 'click_session/exceptions'
require 'support/test_unit_model'

describe ClickSession::Async do
  describe "#run" do
    let(:model) {
      create(:test_unit_model)
    }

    describe "guard clauses" do
      context "when no callback urls has been configured" do
        it "raises a friendly error" do
          async_click_session = ClickSession::Async.new(model)

          expect { async_click_session.run }.to raise_error(ClickSession::ConfigurationError)
        end
      end
    end

    context 'when processing is successful' do
      before do
        mock_configuration_model_class_with(model)
      end

      before :each do
        mock_configuration_callback_urls
        disable_screenshots
      end

      it "saves the session_state" do
        async_click_session = ClickSession::Async.new(model)

        expect { async_click_session.run }.
          to change { ClickSession::SessionState.count }.by(1)
      end

      it "returns a serialized OK response without the model" do
        async_click_session = ClickSession::Async.new(model)

        response = async_click_session.run

        expect(response[:id]).to be_a(Integer)
        expect(response[:status][:success]).to be(true)
        expect(response[:data]).to eql(model.as_json)
      end
    end
  end

  def mock_configuration_callback_urls
    allow(ClickSession.configuration).
      to receive(:success_callback_url).
      and_return("http://success.callback.url")

    allow(ClickSession.configuration).
      to receive(:failure_callback_url).
      and_return("http://failure.callback.url")
  end

  def disable_screenshots
    allow(ClickSession.configuration).
      to receive(:screenshot_enabled?).
      and_return(false)
  end
end