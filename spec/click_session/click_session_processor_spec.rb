require 'spec_helper'
require 'click_session/configuration'
require 'support/test_unit_model'
require 'support/dummy_web_runner'

describe ClickSession::ClickSessionProcessor do
  describe "#process" do
    let(:model) {
      create(:test_unit_model)
    }

    let(:session_state) do
      ClickSession::SessionState.new(model: model)
    end

    before do
      mock_model_class_in_in_configuration(model)
    end

    context 'when processing is successful' do
      before do
        @web_runner_processor_mock = mock_succesful_web_runner_processor
        @notifier_mock = mock_for_notifier
      end

      it "processes the model" do
        click_session_processor = ClickSession::ClickSessionProcessor.new(
          session_state,
          @web_runner_processor_mock,
          @notifier_mock
        )

        click_session_processor.process

        expect(@web_runner_processor_mock).to have_received(:process).with(model)
      end

      it "changes the state of the session_state to 'processed'" do
        click_session_processor = ClickSession::ClickSessionProcessor.new(
          session_state,
          @web_runner_processor_mock,
          @notifier_mock
        )

        click_session_processor.process

        expect(ClickSession::SessionState.last.state_name).to eql(:processed)
      end

      it "returns the session_state" do
        click_session_processor = ClickSession::ClickSessionProcessor.new(
          session_state,
          @web_runner_processor_mock,
          @notifier_mock
        )

        response = click_session_processor.process

        expect(response).to be_a(ClickSession::SessionState)
      end

      it "sends a notification of the success" do
        click_session_processor = ClickSession::ClickSessionProcessor.new(
          session_state,
          @web_runner_processor_mock,
          @notifier_mock
        )

        response = click_session_processor.process

        expect(@notifier_mock).
          to have_received(:session_successful).
          with(session_state)
      end


      it "guards against faulty screenshot configurations" do
        click_session_processor = ClickSession::ClickSessionProcessor.new(
          session_state,
          @web_runner_processor_mock,
          @notifier_mock,
          screenshot_enabled: true,
          screnshot: nil
        )

        expect { click_session_processor.process }.to raise_error(ClickSession::ConfigurationError)
      end

      context 'when saving screenshots is enabled' do
        it "records the url of the screenshot" do
          click_session_processor = ClickSession::ClickSessionProcessor.new(
            session_state,
            @web_runner_processor_mock,
            @notifier_mock,
            screenshot_enabled: true,
            screenshot_options: {
              s3_bucket: "unit-s3",
              s3_key_id: "unit-s3-key",
              s3_access_key: "unit_s3_access_key"
            }
          )

          response = click_session_processor.process

          expect(@web_runner_processor_mock).to have_received(:save_screenshot)
          expect(ClickSession::SessionState.last.screenshot_url).to be_a(String)
        end
      end

      context "when saving screenshot is disabled" do
        it "does not save the screenshot" do
          click_session_processor = ClickSession::ClickSessionProcessor.new(
            session_state,
            @web_runner_processor_mock,
            @notifier_mock
          )

          response = click_session_processor.process

          expect(@web_runner_processor_mock).not_to have_received(:save_screenshot)
          expect(ClickSession::SessionState.last.screenshot_url).to be_nil
        end
      end
    end

    context 'when processing fails' do
      before do
        @web_runner_processor_mock = mock_failing_web_runner_processor
        @notifier_mock = mock_for_notifier
      end

      it "processes the model" do
        click_session_processor = ClickSession::ClickSessionProcessor.new(
          session_state,
          @web_runner_processor_mock,
          @notifier_mock
        )

        begin
          click_session_processor.process
        rescue ClickSession::TooManyRetriesError => e
          expect(@web_runner_processor_mock).to have_received(:process).with(model)
        end
      end

      it "changes the state of the session_state to 'failed_to_process'" do
        click_session_processor = ClickSession::ClickSessionProcessor.new(
          session_state,
          @web_runner_processor_mock,
          @notifier_mock
        )

        begin
          click_session_processor.process
        rescue ClickSession::TooManyRetriesError => e
          expect(ClickSession::SessionState.last.state_name).to eql(:failed_to_process)
        end
      end

      it "raises a TooManyRetriesError" do
        click_session_processor = ClickSession::ClickSessionProcessor.new(
          session_state,
          @web_runner_processor_mock,
          @notifier_mock
        )

        expect { click_session_processor.process }.
          to raise_error(ClickSession::TooManyRetriesError)
      end

      it "sends a notification of the failure" do
        click_session_processor = ClickSession::ClickSessionProcessor.new(
          session_state,
          @web_runner_processor_mock,
          @notifier_mock
        )

        begin
          click_session_processor.process
        rescue ClickSession::TooManyRetriesError => e
          expect(@notifier_mock).
            to have_received(:session_failed).
            with(session_state)
        end
      end

      context 'when saving screenshots is enabled' do
        it "records the url of the screenshot" do
          click_session_processor = ClickSession::ClickSessionProcessor.new(
            session_state,
            @web_runner_processor_mock,
            @notifier_mock,
            screenshot_enabled: true,
            screenshot_options: {
              s3_bucket: "unit-s3",
              s3_key_id: "unit-s3-key",
              s3_access_key: "unit_s3_access_key"
            }
          )

          begin
            click_session_processor.process
          rescue ClickSession::TooManyRetriesError => e
            expect(@web_runner_processor_mock).to have_received(:save_screenshot)
            expect(ClickSession::SessionState.last.screenshot_url).to be_a(String)
          end
        end
      end

      context "when saving screenshot is disabled" do
        it "does not save the screenshot" do
          click_session_processor = ClickSession::ClickSessionProcessor.new(
            session_state,
            @web_runner_processor_mock,
            @notifier_mock
          )

          begin
            click_session_processor.process
          rescue ClickSession::TooManyRetriesError => e
            expect(@web_runner_processor_mock).not_to have_received(:save_screenshot)
            expect(ClickSession::SessionState.last.screenshot_url).to be_nil
          end
        end
      end
    end

    def mock_succesful_web_runner_processor
      processor_stub = DummyWebRunner.new
      web_runner_processor_mock = ClickSession::WebRunnerProcessor.new(processor_stub)

      allow(web_runner_processor_mock).
        to receive(:process).
        with(model).
        and_return(model)

      allow(web_runner_processor_mock).
        to receive(:save_screenshot).
        and_return("http://url.to/success-screenshot")

      allow(ClickSession::WebRunnerProcessor).
        to receive(:new).
        and_return(web_runner_processor_mock)

      web_runner_processor_mock
    end

    def mock_failing_web_runner_processor
      processor_stub = DummyWebRunner.new
      web_runner_processor_mock = ClickSession::WebRunnerProcessor.new(processor_stub)

      allow(web_runner_processor_mock).
        to receive(:process).
        with(model).
        and_raise(ClickSession::TooManyRetriesError, "Error in unit test")

      allow(web_runner_processor_mock).
        to receive(:save_screenshot).
        and_return("http://url.to/failure-screenshot")

      allow(ClickSession::WebRunnerProcessor).
        to receive(:new).
        and_return(web_runner_processor_mock)

      web_runner_processor_mock
    end

    def mock_model_class_in_in_configuration(model_stub)
      model_double = class_double(TestUnitModel)

      # Mock the model_class from the configuration
      allow(model_double).
        to receive(:find_by_id).
        with(model_stub.id).
        and_return(model_stub)

      allow(ClickSession.configuration).
        to receive(:model_class).
        and_return(model_double)
    end

    def mock_for_notifier
      notifier_mock = ClickSession::Notifier.new

      allow(notifier_mock).to receive(:session_failed)
      allow(notifier_mock).to receive(:session_successful)
      allow(notifier_mock).to receive(:rescued_error)

      notifier_mock
    end
  end
end