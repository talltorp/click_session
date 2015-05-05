module ClickSession
  @@configuration = nil

  def self.configure
    @@configuration = Configuration.new

    if block_given?
      yield configuration
    end

    configuration
  end

  def self.configuration
    @@configuration || configure
  end

  class Configuration
    attr_accessor :success_callback_url,
      :failure_callback_url,
      :serializer_class

    def model_class
      if @model_class == nil
        raise NameError.new(<<-ERROR.strip_heredoc, 'model_class')
          To use ClickSession, you must define the name of the active model
          you want ClickSession to operate on.
          See https://github.com/talltorp/click_session for more information.
        ERROR
      end

      @model_class.constantize
    end

    def model_class=(klass)
      @model_class = klass.to_s
    end

    def runner_class
      @runner_class ||=
        begin
          if Kernel.const_defined?(:ClickSessionRunner)
            "ClickSessionRunner"
          else
            raise NameError.new(<<-ERROR.strip_heredoc, 'ClickSessionRunner')
              To use ClickSession, you must either define `ClickSessionRunner` or configure a
              different processor. See https://github.com/talltorp/click_session for
              more information.
            ERROR
          end
        end

      @runner_class.constantize
    end

    def runner_class=(klass)
      @runner_class = klass.to_s
    end

    def serializer_class
      @serializer_class ||= "ClickSession::WebhookModelSerializer"
      @serializer_class.constantize
    end

    def serializer_class=(klass)
      @serializer_class = klass.to_s
    end

    def notifier_class
      @notifier_class ||= "ClickSession::Notifier"
      constantized_notifier = @notifier_class.constantize

      if notifier_class_violates_interface(constantized_notifier)
        raise ArgumentError.new(<<-ERROR.strip_heredoc)
          Your custom notifier must inherit ClickSession::Notifier
          See https://github.com/talltorp/click_session
        ERROR
      end

      constantized_notifier
    end

    def notifier_class=(klass)
      @notifier_class = klass.to_s
    end

    def driver_client
      @driver_client ||= :poltergeist
    end

    def driver_client=(client)
      @driver_client = client
    end

    def screenshot_enabled?
      @screenshot_enabled ||= false
    end

    def enable_screenshot=(enable)
      @screenshot_enabled = enable
    end

    def screenshot
      if @screenshot == nil
        raise ArgumentError.new("In order to save screenshots, you need to configure \
          the information.
          https://github.com/talltorp/click_session#optional-configurations-and-extentions
          ")
      end

      @screenshot
    end

    def screenshot=(screenshot)
      if screenshot[:s3_bucket] == nil
        raise ArgumentError.new("The s3_bucket is required")
      end

      if screenshot[:s3_key_id] == nil
        raise ArgumentError.new("The s3_key_id is required")
      end

      if screenshot[:s3_access_key] == nil
        raise ArgumentError.new("The s3_access_key is required")
      end

      @screenshot = screenshot
    end

    private

    def notifier_class_violates_interface(notifier_class)
      required_methods = ClickSession::Notifier.instance_methods(false)
      actual_methods = notifier_class.instance_methods

      intersection = required_methods - actual_methods

      intersection.length != 0
    end
  end
end