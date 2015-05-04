require "spec_helper"
require "click_session/configuration"

describe ClickSession::WebRunner do
  describe "#point_of_no_return" do
    it "tells its processor it should stop retrying errors" do
      processor = ClickSession::WebRunnerProcessor.new
      allow(processor).to receive(:stop_processing)
      web_runner = ClickSession::WebRunner.new(processor)

      web_runner.point_of_no_return

      expect(processor).to have_received(:stop_processing).once
    end
  end

  describe "#save_screenshot" do
    context 'when screenshot was successful' do
      before :each do
        ClickSession.configure do | config |
          config.enable_screenshot = true
          config.screenshot = {
            s3_bucket: 'unit-s3-bucket',
            s3_key_id: 'unit-s3-key-id',
            s3_access_key: 'unit-s3-access-key'
          }
          allow(ClickSession.configuration).
            to receive(:screenshot_enabled?).
            and_return(true)

          allow(ClickSession.configuration).
            to receive(:screenshot).
            and_return({
              s3_bucket: 'unit-s3-bucket',
              s3_key_id: 'unit-s3-key-id',
              s3_access_key: 'unit-s3-access-key'
            })
        end
      end

      it "saves the screenshot in an s3 bucket" do
        processor = ClickSession::WebRunnerProcessor.new
        runner = ClickSession::WebRunner.new(processor)
        stub_capybara
        stub_s3

        runner.save_screenshot("unit-id")
      end

      it "returns the url to the saved screenshot" do
        processor = ClickSession::WebRunnerProcessor.new
        runner = ClickSession::WebRunner.new(processor)
        stub_capybara
        stub_s3

        screenshot_url = runner.save_screenshot("unit-id")

        expect(screenshot_url).to be_a(String)
      end

      def stub_capybara
        allow_any_instance_of(Capybara::Session).
          to receive(:save_screenshot)
      end

      def stub_s3
        expect_any_instance_of(ClickSession::S3FileUploader).
          to receive(:upload_file).
          with(/unit-id/).
          and_return("https://unit-bucket.s3.aws.com/filename.png")
      end
    end

    context 'when the screenshot fails' do
      it "does not try to save anything" do
        processor = ClickSession::WebRunnerProcessor.new
        runner = ClickSession::WebRunner.new(processor)

        allow_any_instance_of(Capybara::Session).
          to receive(:save_screenshot).
          and_raise

        expect_any_instance_of(ClickSession::S3FileUploader).
          not_to receive(:upload_file).
          with(/unit-id/)

        expect { runner.save_screenshot("unit-id") }.
          to raise_error
      end
    end
  end
end