require "spec_helper"
require "click_session/configuration"
require 'support/test_unit_model'

describe ClickSession::StatusReporter do
  describe "#report" do
    let(:session_state) { build_session_state_in_processed_state }
    let(:model) { create(:test_unit_model) }

    before :each do
      @notifier_stub = stub_notifier_in_configuration

      mock_configuration_model_class_with(model)
    end

    context 'when the reporting endpoint is online' do
      it "reports the successfull order back" do
        status_reporter = ClickSession::SuccessfulStatusReporter.new(
          ok_webhook_stub
        )

        expect { status_reporter.report(session_state) }.
          not_to raise_error
      end

      it "changes the state to 'success_reported'" do
        status_reporter = ClickSession::SuccessfulStatusReporter.new(
          ok_webhook_stub
        )

        status_reporter.report(session_state)

        expect(session_state.success_reported?).to eql(true)
      end

      it "notifies about the successful reporting" do
          status_reporter = ClickSession::SuccessfulStatusReporter.new(
            ok_webhook_stub
          )

          status_reporter.report(session_state)

          expect(@notifier_stub).
            to have_received(:session_reported).
            with(session_state)
        end

      context 'with a serializer_class in the configuration' do
        it "serializes the response with the user defined serializer" do
          class MyDefinedSerializer < ClickSession::WebhookModelSerializer
            def serialize(model)
              {
                user_defined: "Serializer"
              }
            end
          end

          serializer_double = double(MyDefinedSerializer)
          serializer_stub = MyDefinedSerializer.new

          # Add the stub to the double
          allow(serializer_double).
            to receive(:new).
            and_return(serializer_stub)

          # Make the configuration return our double
          allow(ClickSession.configuration).
            to receive(:serializer_class).
            and_return(serializer_double)

          webhook_stub = ClickSession::Webhook.new("a-unit-test-web-hook.url")
          allow(webhook_stub).
            to receive(:call)

          status_reporter = ClickSession::SuccessfulStatusReporter.new(
            webhook_stub
          )

          status_reporter.report(session_state)

          expect(webhook_stub).
            to have_received(:call).
            with( {
              id: session_state.id,
              status: {
                success: true
              },
              data:{
                user_defined: "Serializer"
               }
            } )
        end
      end
    end

    context 'when the reporting endpoint is offline' do
      it "leaves the state in 'processed'" do
        status_reporter = ClickSession::SuccessfulStatusReporter.new(
          failing_webhook_stub
        )

        status_reporter.report(session_state)

        expect(session_state.processed?).to eql(true)
      end

      it "notifies about the rescued error" do
        status_reporter = ClickSession::SuccessfulStatusReporter.new(
          failing_webhook_stub
        )

        status_reporter.report(session_state)

        expect(@notifier_stub).to have_received(:rescued_error).once
      end

      context 'when the retry threshold has been reached' do
        it "notifies the status_notifier about the threshold" do
          session_state.webhook_attempts = 4

          status_reporter = ClickSession::SuccessfulStatusReporter.new(
            failing_webhook_threshold_reached_stub
          )

          status_reporter.report(session_state)

          expect(@notifier_stub).to have_received(:rescued_error).once

          expect(@notifier_stub).
            to have_received(:session_failed_to_report).
            with(session_state)
        end
      end
    end

    def ok_webhook_stub
      unless @webhook
        @webhook = ClickSession::Webhook.new("a-unit-test-web-hook.url")
        expect(@webhook).
          to receive(:call).
          with(anything)
      end
      @webhook
    end

    def failing_webhook_stub
      unless @webhook
        @webhook = ClickSession::Webhook.new("a-unit-test-web-hook.url")
        expect(@webhook).
          to receive(:call).
          with(anything).
          and_raise(StandardError)
      end
      @webhook
    end

    def failing_webhook_threshold_reached_stub
      unless @webhook
        @webhook = ClickSession::Webhook.new("a-unit-test-web-hook.url")
        expect(@webhook).
          to receive(:call).
          with(anything).
          and_raise(StandardError)
      end
      @webhook
    end

    def stub_notifier_in_configuration
      notifier_double = double(ClickSession::Notifier)
      notifier_stub = ClickSession::Notifier.new

      # Stub the method
      allow(notifier_stub).
        to receive(:session_failed_to_report)

      allow(notifier_stub).
        to receive(:session_reported)

      allow(notifier_stub).
        to receive(:rescued_error)

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

    def build_session_state_in_processed_state
      ClickSession::SessionState.create(state: 1, model_record: model.id)
    end
  end
end