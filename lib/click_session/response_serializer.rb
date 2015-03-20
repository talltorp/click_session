module ClickSession
  class ResponseSerializer
    def serialize_success(click_session)
      {
        id: click_session.id,
        status: {
          success: true
        },
        data: serializer.serialize(click_session.model)
      }
    end

    def serialize_failure(click_session)
      {
        id: click_session.id,
        status: {
          success: false
        }
      }
    end

    private

    delegate :serializer_class, :notifier_class, to: :clicksession_configuration

    def serializer
      @serializer ||= serializer_class.new
    end

    def clicksession_configuration
      ClickSession.configuration
    end
  end
end