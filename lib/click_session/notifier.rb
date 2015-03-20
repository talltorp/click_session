module ClickSession
  class Notifier
    def session_successful(click_session)
      puts "SUCCESS: #{click_session.id} completed"
    end

    def session_failed(click_session)
      $stderr.puts "FAILURE: #{click_session.id} failed"
    end

    def session_reported(click_session)
      puts "REPORTED: #{click_session.id} successfully reported"
    end

    def session_failed_to_report(click_session)
      $stderr.puts "REPORT_FAIL: #{click_session.id} failed to report"
    end

    def rescued_error(e)
      puts "#{e.class.name}: #{e.message}"
    end
  end
end