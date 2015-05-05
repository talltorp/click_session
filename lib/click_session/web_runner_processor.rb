require_relative "./exceptions"

module ClickSession
  class WebRunnerProcessor
    def initialize
      @retries_made  = 0
      @making_requests = true
    end

    delegate :runner_class, :notifier_class, to: :clicksession_configuration

    def process(model)
      while can_make_requests?
        begin
          run_steps_in_browser_with(model)
        rescue StandardError => e
          make_note_of_error(e)

          if too_many_retries?
            raise TooManyRetriesError.new
          end
        end
      end

      model
    end

    def stop_processing
      @making_requests = false
    end

    delegate :save_screenshot, to: :web_runner

    private

    def can_make_requests?
      @making_requests
    end

    def run_steps_in_browser_with(model)
      web_runner.reset
      web_runner.run(model)
      stop_processing
    end

    def make_note_of_error(error)
      @retries_made += 1
      notifier.rescued_error(error)
    end

    def too_many_retries?
      @retries_made > 2
    end

    def web_runner
      @web_runner ||= runner_class.new(self)
    end

    def notifier
      @notifier ||= notifier_class.new
    end

    def clicksession_configuration
      ClickSession.configuration
    end
  end
end