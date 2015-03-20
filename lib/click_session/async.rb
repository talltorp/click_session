module ClickSession
  class Async
    attr_reader :model
    attr_accessor :click_session

    def initialize(model)
      @model = model
    end

    def run
      validate_async_configuration

      @click_session = SessionState.create(model: model)
      serialize_success_response
    end

    private

    def validate_async_configuration
      if success_callback_missing? || failure_callback_missing?
        raise ConfigurationError.new("You need to configure the callback URLs in order to use the AsyncClickSession")
      end
    end

    def success_callback_missing?
      ClickSession.configuration.success_callback_url == nil
    end

    def failure_callback_missing?
      ClickSession.configuration.failure_callback_url == nil
    end

    def serialize_success_response
      serializer.serialize_success(click_session)
    end

    def serialize_failure_response
      serializer.serialize_failure(click_session)
    end

    def serializer
      @serializer ||= ClickSession::ResponseSerializer.new
    end
  end
end