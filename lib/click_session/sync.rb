module ClickSession

  # Executes the click session and retuns a serialized response
  class Sync
    attr_reader :model
    attr_accessor :click_session

    def initialize(model)
      @model = model
    end

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

    delegate :notifier_class, to: :clicksession_configuration

    def serialize_success_response
      serializer.serialize_success(click_session)
    end

    def serialize_failure_response
      serializer.serialize_failure(click_session)
    end

    def processor
      @processor ||= ClickSession::WebRunnerProcessor.new
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

    def serializer
      @serializer ||= ClickSession::ResponseSerializer.new
    end
  end
end