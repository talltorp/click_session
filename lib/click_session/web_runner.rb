require 'capybara'
require 'capybara/poltergeist'

CAPYBARA_ERRORS = [
  Capybara::ElementNotFound
]

module ClickSession
  class WebRunner
    include Capybara::DSL

    def initialize
      Capybara.default_driver = ClickSession.configuration.driver_client
      Capybara.javascript_driver = ClickSession.configuration.driver_client
      Capybara.run_server = false
      page = Capybara::Session.new(ClickSession.configuration.driver_client)
    end

    def run
      raise NotImplementedError("You need to override the #steps method by sub classing WebRunner")
    end

    def reset
      clear_cookies
    end

    def save_screenshot(file_name_identity = "")
      @file_name = build_file_name_for(file_name_identity)
      page.save_screenshot(screenshot_save_path, full: true)

      S3FileUploader.new.upload_file(@file_name)
    end

    private
    def clear_cookies
      browser = Capybara.current_session.driver.browser

      if browser.respond_to?(:manage) and browser.manage.respond_to?(:delete_all_cookies)
        browser.manage.delete_all_cookies
      else
        page.driver.cookies.keys.each do |cookie|
          page.driver.remove_cookie(cookie)
        end
      end
    end

    def screenshot_save_path
      path_for(@file_name)
    end

    def build_file_name_for(file_name_identity)
      readable_date = Time.now.strftime("%F_%T")
      "screenshot-#{file_name_identity}-#{readable_date}.png"
    end

    def path_for(file_name)
      "#{Rails.root}/tmp/#{file_name}"
    end
  end
end