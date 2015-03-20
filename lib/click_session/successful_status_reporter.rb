module ClickSession
  class SuccessfulStatusReporter < StatusReporter
    def initialize(
      webhook = Webhook.new(ClickSession.configuration.success_callback_url)
    )
      super(webhook)
    end

    def report(click_session)
      raise ArgumentError unless click_session.processed?

      super(click_session)
    end
  end
end