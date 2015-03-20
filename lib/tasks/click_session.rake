require "click_session/configuration"

namespace :click_session do
  desc "Processes all click_sessions in the 'active' state"
  task process_active: :environment do
    def processor_for(session_state)
      ClickSession::ClickSessionProcessor.new(
        session_state,
        ClickSession::WebRunnerProcessor.new(configured_web_runner),
        ClickSession.configuration.notifier_class.new,
        processor_options
      )
    end

    def configured_web_runner
      ClickSession.configuration.processor_class.new
    end

    def processor_options
      if ClickSession.configuration.screenshot_enabled?
        {
          screenshot_enabled: true,
          screenshot_options: ClickSession.configuration.screenshot
        }
      else
        {}
      end
    end

    ClickSession::SessionState.with_state(:active).each do | session_state |
      processor_for(session_state).process
    end
  end

  desc "reports click_sessions in 'processed' state to the webhook"
  task report_processed: :environment do
    reporter = ClickSession::SuccessfulStatusReporter.new

    ClickSession::SessionState.with_state(:processed).each do | session_state |
      reporter.report(session_state)
    end
  end

  desc "reports click_sessions in 'failed' state to the webhook"
  task report_failed: :environment do
    reporter = ClickSession::FailureStatusReporter.new

    ClickSession::SessionState.with_state(:failed_to_process).each do | session_state |
      reporter.report(session_state)
    end
  end
end