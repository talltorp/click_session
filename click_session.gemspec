# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'click_session/version'

Gem::Specification.new do |spec|
  spec.name          = "click_session"
  spec.version       = ClickSession::VERSION
  spec.authors       = ["Tobias Talltorp"]
  spec.email         = ["tobias@talltorp.se"]
  spec.summary       = "Navigates the web for you"
  spec.description   = "Navigates the web for you"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'rails', '>= 4.1'
  spec.add_dependency 'capybara', "~> 2.4"
  spec.add_dependency 'poltergeist', "~> 1.6"
  spec.add_dependency 'rest-client', "~> 1.7"
  spec.add_dependency 'state_machine', "~> 1.2"
  spec.add_dependency 'aws-sdk-v1', "~> 1.63"
  spec.add_dependency 'selenium-webdriver', "~> 2.45"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-rails", "~> 3.1"
  spec.add_development_dependency "factory_girl_rails", "~> 4.2"
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'webmock', '~> 1.18'
  spec.add_development_dependency "sqlite3"
end
