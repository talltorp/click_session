require 'spec_helper'
require "click_session/configuration"
require "support/test_unit_model"
require "support/click_session_runner"

describe ClickSession::WebRunnerProcessor do
  describe "#process" do
    let(:model) { create(:test_unit_model) }

    before :each do
      @notifier_stub = stub_notifier_in_configuration
      mock_configuration_model_class_with(model)
    end

    context "when all requests are ok" do
      it "returns the enriched model" do
        web_runner = ok_web_runner_stub(model)
        stub_web_runner_in_configuration_with(web_runner)
        web_runner_processor = ClickSession::WebRunnerProcessor.new

        enriched_model = web_runner_processor.process(model)

        expect(enriched_model).to be_a(TestUnitModel)
      end
    end

    context "when the placing of the order fails" do
      before(:each) do
        @times_called = 0
      end

      describe "but third retry succeeds" do
        it "the state has changed to 'processed'" do
          web_runner = third_time_ok_web_runner_stub(model)
          stub_web_runner_in_configuration_with(web_runner)
          web_runner_processor = ClickSession::WebRunnerProcessor.new

          enriched_model = web_runner_processor.process(model)

          expect(enriched_model).to be_a(TestUnitModel)
        end

        it "notifies about the rescued error" do
          web_runner = third_time_ok_web_runner_stub(model)
          stub_web_runner_in_configuration_with(web_runner)
          web_runner_processor = ClickSession::WebRunnerProcessor.new

          web_runner_processor.process(model)

          expect(@notifier_stub).to have_received(:rescued_error).twice
        end

        def third_time_ok_web_runner_stub(model)
          web_runner = ClickSessionRunner.new
          allow(web_runner).
            to receive(:run).
            with(model) do | args |
              @times_called += 1

              raise StandardError, "Assertion failed" if @times_called < 3
            end

          allow(web_runner).to receive(:reset)

          web_runner
        end
      end

      describe "when all retry attempts fail" do
        it "raises an error and notifies the status_notifier of each error" do
          web_runner = all_requests_fail_web_runner_stub(model)
          stub_web_runner_in_configuration_with(web_runner)
          web_runner_processor = ClickSession::WebRunnerProcessor.new

          expect { web_runner_processor.process(model) }.
            to raise_error(ClickSession::TooManyRetriesError)
          expect(@notifier_stub).
            to have_received(:rescued_error).
            exactly(3).times
        end
      end

      context "when further retries have been explicitly canceled" do
        it "no more requests are made" do
          web_runner = ok_web_runner_stub(model)
          stub_web_runner_in_configuration_with(web_runner)
          web_runner_processor = ClickSession::WebRunnerProcessor.new

          web_runner_processor.stop_processing
          enriched_model = web_runner_processor.process(model)

          expect(web_runner).not_to receive(:run)
        end
      end
    end
  end

  describe "#save_screenshot_for" do
    it "delegates :save_screenshot to WebRunner" do
      model = create(:test_unit_model)
      web_runner = ok_web_runner_stub(model)
      stub_web_runner_in_configuration_with(web_runner)
      web_runner_processor = ClickSession::WebRunnerProcessor.new

      web_runner_processor.save_screenshot("a_unique_name")

      expect(web_runner).to have_received(:save_screenshot).with("a_unique_name")
    end
  end

  def stub_web_runner_in_configuration_with(web_runner_stub)
    web_runner_double = class_double(ClickSession::WebRunner)

    # Add the stub to the double
    allow(web_runner_double).
      to receive(:new).
      and_return(web_runner_stub)

    # Make the configuration return our double
    allow(ClickSession.configuration).
      to receive(:web_runner_class).
      and_return(web_runner_double)

    web_runner_stub
  end

  def stub_notifier_in_configuration
    notifier_double = class_double(ClickSession::Notifier)
    notifier_stub = ClickSession::Notifier.new

    # Stub the methods
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

  def ok_web_runner_stub(model)
    web_runner = ClickSessionRunner.new
    allow(web_runner).
      to receive(:run).
      with(model)

    allow(web_runner).
      to receive(:reset)

    allow(web_runner).
      to receive(:save_screenshot).
      and_return("a_file_name")

    web_runner
  end

  def all_requests_fail_web_runner_stub(model)
    web_runner = ClickSessionRunner.new

    allow(web_runner).
      to receive(:run).
      with(model).
      and_raise(StandardError.new)

    allow(web_runner).
      to receive(:reset)

    web_runner
  end
end