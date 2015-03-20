module ClickSession
  class Base
    attr_reader :model
    attr_accessor :click_session

    def initialize(model)
      @model = model
    end

    private
    delegate :screenshot_enabled?, :screenshot, to: :clicksession_configuration

    def serialize_success_response
      serializer.serialize_success(click_session)
    end

    def serialize_failure_response
      serializer.serialize_failure(click_session)
    end

    def processor
      @processor ||= ClickSession::WebRunnerProcessor.new(web_runner)
    end

    def web_runner
      @sweb_runner ||= processor_class.new
    end

    def serializer
      @serializer ||= ClickSession::ResponseSerializer.new
    end

    def clicksession_configuration
      ClickSession.configuration
    end
  end
end