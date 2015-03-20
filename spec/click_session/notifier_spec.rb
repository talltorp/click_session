require 'spec_helper'
require 'support/test_unit_model'

describe ClickSession::Notifier do
  describe "#session_successful" do
    it "logs success information about the click_session to stdout" do
      session_state = ClickSession::SessionState.create({
        state: 1,
        model: build(:test_unit_model)
      })
      notifier = ClickSession::Notifier.new

      expect { notifier.session_successful(session_state) }.
        to output(/SUCCESS(.*)#{session_state.id}/).
        to_stdout
    end
  end

  describe "#session_failed" do
    it "logs failure information about the click_session to stdout" do
      session_state = ClickSession::SessionState.create({
        state: 2,
        model: build(:test_unit_model)
      })
      notifier = ClickSession::Notifier.new

      expect { notifier.session_failed(session_state) }.
        to output(/FAILURE(.*)#{session_state.id}/).
        to_stderr
    end
  end

  describe "#session_reported" do
    it "logs report success information about the click_session to stdout" do
      session_state = ClickSession::SessionState.create({
        state: 1,
        model: build(:test_unit_model)
      })
      notifier = ClickSession::Notifier.new

      expect { notifier.session_reported(session_state) }.
        to output(/REPORTED(.*)#{session_state.id}/).
        to_stdout
    end
  end

  describe "#session_failed_to_report" do
    it "logs that the report failed for the click_session to stdout" do
      session_state = ClickSession::SessionState.create({
        state: 2,
        model: build(:test_unit_model)
      })
      notifier = ClickSession::Notifier.new

      expect { notifier.session_failed_to_report(session_state) }.
        to output(/REPORT_FAIL(.*)#{session_state.id}/).
        to_stderr
    end
  end

  describe "#rescued_error" do
    it "logs the exception to stdout" do
      exception = ArgumentError.new("unit argument error")

      notifier = ClickSession::Notifier.new

      expect { notifier.rescued_error(exception) }.
        to output(/ArgumentError/).
        to_stdout
    end
  end
end