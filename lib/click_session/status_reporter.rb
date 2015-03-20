module ClickSession
  class StatusReporter

    MAX_WEBHOOK_ATTEMPTS = 5

    def initialize(webhook)
      @webhook = webhook
    end

    delegate :serializer_class, :notifier_class, to: :clicksession_configuration

    def report(click_session)
      @click_session = click_session

      begin
        webhook.call(
          serialized_webhook_message
        )

        @click_session.reported_back!
        notifier.session_reported(@click_session)
      rescue StandardError => e
        notifier.rescued_error(e)
        handle_webhook_failure
      end
    end

    private

    attr_reader :webhook

    def serialized_webhook_message
      if @click_session.processed?
        serialize_success_message
      else
        serialize_error_message
      end
    end

    def serialize_success_message
      {
        id: @click_session.id,
        status: {
          success: true
        },
        data: serializer.serialize(@click_session.model)
      }
    end

    def serialize_error_message
      {
        id: @click_session.id,
        status: {
          success: false,
          message: "See error logs"
        }
      }
    end

    def handle_webhook_failure
      @click_session.webhook_attempt_failed
      @click_session.save!

      if @click_session.webhook_attempts >= MAX_WEBHOOK_ATTEMPTS
        notifier.session_failed_to_report(@click_session)
      end
    end

    def notifier
      @notifier ||= notifier_class.new
    end

    def serializer
      @serializer ||= serializer_class.new
    end

    def clicksession_configuration
      ClickSession.configuration
    end
  end
end