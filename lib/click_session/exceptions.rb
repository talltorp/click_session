module ClickSession
  # A general ClickSession exception
  class Error < StandardError; end

  # Raised when the threshold has been reached for how many retries we
  # make of running the steps provided before we consider the entire
  # session a failure
  class TooManyRetriesError < Error; end

  # Raised when the configuration is not properly initialized
  class ConfigurationError < Error; end
end