module ClickSession

  # Executes the click session and retuns a serialized response
  class SyncClickSession < Base
    def run
      @click_session = SessionState.create!(model: model)

      begin
        click_session_processor = ClickSessionProcessor.new(
          click_session,
          processor,
          configured_notifier,
          options
        )

        click_session_processor.process

        click_session.reported_back!
        serialize_success_response
      rescue TooManyRetriesError => e
        click_session.reported_back!
        serialize_failure_response
      end
    end

    private

    delegate :processor_class, :notifier_class, to: :clicksession_configuration

    def processor
      @processor ||= ClickSession::WebRunnerProcessor.new(configured_web_runner)
    end

    def configured_web_runner
      @web_runner ||= processor_class.new
    end

    def configured_notifier
      @notifier ||= notifier_class.new
    end

    def options
      if clicksession_configuration.screenshot_enabled?
        {
          screenshot_enabled: true,
          screenshot_options: clicksession_configuration.screenshot
        }
      else
        {}
      end
    end

    def clicksession_configuration
      ClickSession.configuration
    end
  end
end