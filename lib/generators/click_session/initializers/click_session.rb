ClickSession.configure do |config|
  config.model_class = RenameThisToYourOwnActiveModelClass
  config.processor_class = ClickSessionRunner
end