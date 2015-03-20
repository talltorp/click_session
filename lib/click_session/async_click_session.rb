module ClickSession
  class AsyncClickSession < Base

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
  end
end