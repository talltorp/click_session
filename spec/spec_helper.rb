require "click_session"
require "factory_girl_rails"
require "factories/test_unit_model_factory"
require "shoulda-matchers"
require "active_record"
require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: true)

# Use memeory database when testing
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
require 'support/schema'


RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.order = :random

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
  end
end

# Helper methods
def mock_configuration_model_class_with(model)
  model_double = class_double(TestUnitModel)

  allow(model_double).
    to receive(:find_by_id).
    with(model.id).
    and_return(model)

  allow(ClickSession.configuration).
    to receive(:model_class).
    and_return(model_double)

  model
end