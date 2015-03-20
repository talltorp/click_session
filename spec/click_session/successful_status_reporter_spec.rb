require "spec_helper"
require "click_session/configuration"
require 'support/test_unit_model'

describe ClickSession::SuccessfulStatusReporter do
  describe "#report" do
    let(:model) { create(:test_unit_model) }

    before do
      stub_notifier_in_configuration
      mock_configuration_model_class_with(model)
    end

    it "rejects shippings not processed" do
      session_state = build_session_state_in_not_processed_state
      status_reporter = ClickSession::SuccessfulStatusReporter.new

      expect { status_reporter.report(session_state) }.
        to raise_error(ArgumentError)
    end

    it "rejects shippings which have failed" do
      session_state = build_session_state_in_failed_state
      status_reporter = ClickSession::SuccessfulStatusReporter.new

      expect { status_reporter.report(session_state) }.
        to raise_error(ArgumentError)
    end

    it "reports with an OK status" do
      session_state = build_session_state_in_processed_state
      webhook_stub = ClickSession::Webhook.new("success.url")
      allow(webhook_stub).to receive(:call)

      status_reporter = ClickSession::SuccessfulStatusReporter.new(
        webhook_stub
      )

      status_reporter.report(session_state)

      expect(webhook_stub).
        to have_received(:call).
        with({
          id: session_state.id,
          status: {
            success: true
          },
          data: session_state.model.as_json
        })
    end

    def stub_notifier_in_configuration
      notifier_double = class_double(ClickSession::Notifier)
      notifier_stub = ClickSession::Notifier.new

      # Stub the methods
      allow(notifier_stub).
        to receive(:session_reported)

      # Add the stub to the double
      allow(notifier_double).
        to receive(:new).
        and_return(notifier_stub)

      # Make the configuration return our double
      allow(ClickSession.configuration).
        to receive(:notifier_class).
        and_return(notifier_double)

      notifier_stub
    end

    def build_session_state_in_not_processed_state
      ClickSession::SessionState.create(state: 0, model_record: model.id)
    end

    def build_session_state_in_processed_state
      ClickSession::SessionState.create(state: 1, model_record: model.id)
    end

    def build_session_state_in_failed_state
      ClickSession::SessionState.create(state: 2, model_record: model.id)
    end
  end
end