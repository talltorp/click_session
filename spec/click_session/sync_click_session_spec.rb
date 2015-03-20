require 'spec_helper'
require 'click_session/configuration'
require 'support/test_unit_model'

describe ClickSession::SyncClickSession do
  describe "#run" do

    let(:model) { create(:test_unit_model) }

    before do
      @notifier_stub = stub_notifier_in_configuration
      mock_configuration_model_class_with(model)

      processor_stub = ClickSession::WebRunner.new
      mock_configuration_processor_class_with(processor_stub)
      @web_runner_processor_stub = stub_web_runner_processor_with( processor_stub )
    end

    context 'when processing is successful' do
      before :each do
        click_session_processor_mock = mock_click_session_processor_with(
          @web_runner_processor_stub,
          @notifier_stub
        )

        expect_any_instance_of(ClickSession::SessionState).
          to receive(:reported_back!)

        disable_screenshots
      end

      it "saves the session_state" do
        sync_click_session = ClickSession::SyncClickSession.new(model)

        expect { sync_click_session.run }.
          to change { ClickSession::SessionState.count }.by(1)
      end

      it "processes the session" do
        sync_click_session = ClickSession::SyncClickSession.new(model)

        sync_click_session.run

        expect(ClickSession::ClickSessionProcessor).
          to have_received(:new).
          with(
            ClickSession::SessionState,
            @web_runner_processor_stub,
            @notifier_stub,
            anything
          )
      end

      context 'with screenshot is enabled' do
        it "passes the configuration on to the ClickSessionRunner" do
          screenshot_configuration = {
              s3_bucket: "unit-s3",
              s3_key_id: "unit-s3-key",
              s3_access_key: "unit_s3_access_key"
            }

          allow(ClickSession.configuration).
            to receive(:screenshot_enabled?).
            and_return(true)

          allow(ClickSession.configuration).
            to receive(:screenshot).
            and_return(screenshot_configuration)

          sync_click_session = ClickSession::SyncClickSession.new(model)

          sync_click_session.run

          expect(ClickSession::ClickSessionProcessor).
            to have_received(:new).
            with(
              ClickSession::SessionState,
              @web_runner_processor_stub,
              @notifier_stub,
              {
                screenshot_enabled: true,
                screenshot_options: screenshot_configuration
              }
            )
        end
      end

      it "uses the web_runner and notifier from the configuration" do
        sync_click_session = ClickSession::SyncClickSession.new(model)

        sync_click_session.run

        expect(ClickSession.configuration).to have_received(:notifier_class)
        expect(ClickSession.configuration).to have_received(:processor_class)
      end

      it "changes the state of the click_session to 'success_reported'" do
        sync_click_session = ClickSession::SyncClickSession.new(model)

        sync_click_session.run

        # Expectation is in the 'before' method
      end

      it "returns a serialized OK response with the model" do
        sync_click_session = ClickSession::SyncClickSession.new(model)

        response = sync_click_session.run

        expect(response[:id]).to be_a(Integer)
        expect(response[:status][:success]).to be(true)
        expect(response[:data]).to eql(model.as_json)
      end
    end

    context 'when processing fails' do
      before :each do
        mock_click_session_processor_and_raise_error(
          @web_runner_processor_stub,
          @notifier_stub
        )

        expect_any_instance_of(ClickSession::SessionState).
          to receive(:reported_back!)

        disable_screenshots
      end

      it "saves the session_state" do
        sync_click_session = ClickSession::SyncClickSession.new(model)

        expect { sync_click_session.run }.
          to change { ClickSession::SessionState.count }.by(1)
      end

      it "returns a serialized FAIL response" do
        sync_click_session = ClickSession::SyncClickSession.new(model)

        response = sync_click_session.run

        expect(response[:id]).to be_a(Integer)
        expect(response[:status][:success]).to be(false)
        expect(response[:data]).to be_nil
      end

      it "changes the state of the click_session to 'reported'" do
        sync_click_session = ClickSession::SyncClickSession.new(model)

        sync_click_session.run

        # Expectation in the 'before do ...'
      end
    end
  end

  def mock_configuration_processor_class_with(processor_stub)
    processor_double = class_double(ClickSession::WebRunner)
    allow(processor_double).
      to receive(:new).
      and_return(processor_stub)

    allow(ClickSession.configuration).
      to receive(:processor_class).
      and_return(processor_double)
  end

  def mock_configuration_notifier_class_with(notifier_mock)
    notifier_double = class_double(ClickSession::Notifier)
    allow(notifier_double).
      to receive(:new).
      and_return(notifier_mock)

    allow(ClickSession.configuration).
      to receive(:processor_class).
      and_return(notifier_double)

    notifier_mock
  end

  def disable_screenshots
    allow(ClickSession.configuration).
      to receive(:screenshot_enabled?).
      and_return(false)
  end


  def stub_web_runner_processor_with(processor_stub)
    web_runner_processor_stub = ClickSession::WebRunnerProcessor.new(processor_stub)

    allow(web_runner_processor_stub).
      to receive(:process).
      with(model).
      and_return(model)

    allow(ClickSession::WebRunnerProcessor).
      to receive(:new).
      and_return(web_runner_processor_stub)

    web_runner_processor_stub
  end

  def mock_click_session_processor_with(processor_stub, notifier_stub)
    click_session_processor_mock = ClickSession::ClickSessionProcessor.new(
      ClickSession::SessionState.new,
      processor_stub,
      notifier_stub
    )

    allow(click_session_processor_mock).
      to receive(:process)

    allow(ClickSession::ClickSessionProcessor).
      to receive(:new).
      and_return(click_session_processor_mock)
  end

  def mock_click_session_processor_and_raise_error(processor_stub, notifier_stub)
    click_session_processor_mock = ClickSession::ClickSessionProcessor.new(
      ClickSession::SessionState.new,
      processor_stub,
      notifier_stub
    )

    allow(click_session_processor_mock).
      to receive(:process).
      and_raise(ClickSession::TooManyRetriesError)

    allow(ClickSession::ClickSessionProcessor).
      to receive(:new).
      and_return(click_session_processor_mock)
  end

  def stub_notifier_in_configuration
    notifier_double = class_double(ClickSession::Notifier)
    notifier_stub = ClickSession::Notifier.new

    # Stub the methods
    allow(notifier_stub).
      to receive(:session_failed)

    allow(notifier_stub).
      to receive(:session_successful)

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
end