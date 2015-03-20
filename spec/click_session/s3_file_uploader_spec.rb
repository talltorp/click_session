require "spec_helper"

describe ClickSession::S3FileUploader do
  describe "#upload_file_from"
    it "returns the full url to the uploaded file" do
      file_name = "unit-identifier-123.png"
      key = "unit_key"
      secret = "unit_secret"
      bucket = "unit_bucket_name"

      s3_connection = ClickSession::S3Connection.new(
          key,
          secret,
          bucket
        )
      allow(s3_connection).
        to receive(:upload_from_filesystem_to_bucket)

      uploader = ClickSession::S3FileUploader.new(s3_connection)
      screenshot_url = uploader.upload_file(file_name)

      expect(screenshot_url).to eql("https://s3.amazonaws.com/#{bucket}/#{file_name}")
    end
end