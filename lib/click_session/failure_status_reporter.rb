module ClickSession
  class FailureStatusReporter < StatusReporter
    def initialize(
      webhook = Webhook.new(ClickSession.configuration.failure_callback_url)
    )
      super(webhook)
    end

    def report(click_session)
      raise ArgumentError unless click_session.failed_to_process?

      super(click_session)
    end
  end
end