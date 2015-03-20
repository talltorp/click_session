require_relative './exceptions'

module ClickSession
  class ClickSessionProcessor
    attr_accessor :click_session
    attr_reader :web_runner_processor, :notifier, :screenshot_enabled, :screenshot_options

    def initialize(click_session, web_runner_processor, notifier, options = {})
      @click_session = click_session
      @web_runner_processor = web_runner_processor
      @notifier = notifier
      @screenshot_enabled = options[:screenshot_enabled] || false
      @screenshot_options = options[:screenshot_options] || nil
    end

    def process
      validate_screenshot_configuration

      begin
        process_provided_steps_in_session
      rescue TooManyRetriesError => e
        take_care_of_failed_session
        raise e
      end

      click_session
    end

    private

    def validate_screenshot_configuration
      if screenshot_enabled
        if screenshot_options == nil
          raise ConfigurationError.new(<<-ERROR.strip_heredoc)
            In order to save screenshots, you need to enter s3 information
            in the 'screenshot' option of the configuration
            See https://github.com/talltorp/click_session for more information.
          ERROR
        end
      end
    end

    def process_provided_steps_in_session
      web_runner_processor.process(click_session.model)
      click_session.success!
      notifier.session_successful(click_session)

      if screenshot_enabled
        click_session.screenshot_url = web_runner_processor.save_screenshot(click_session.id)
        click_session.save
      end
    end

    def take_care_of_failed_session
      click_session.failure!
      notifier.session_failed(click_session)

      if screenshot_enabled
        click_session.screenshot_url = web_runner_processor.save_screenshot(click_session.id)
        click_session.save
      end
    end
  end
end