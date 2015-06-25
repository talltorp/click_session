require "spec_helper"

class ClientStub
  def buckets
    { "unit-bucket" => BucketStub.new }
  end
end

class BucketStub
  def objects
    { "filename" => ObjectStub.new }
  end
end

class ObjectStub
  def write(path, options)

  end
end

describe ClickSession::S3Connection do
  describe "#upload_from_filesystem_to_bucket" do
    it "uploads the file to an S3 bucket" do
      key_id = "unit-key-id"
      access_key = "unit-access-key"
      bucket_name = "unit-bucket"
      aws_client_stub = ClientStub.new
      allow(AWS::S3).to receive(:new).and_return(aws_client_stub)
      connection = ClickSession::S3Connection.new(key_id, access_key, bucket_name)

      connection.upload_from_filesystem_to_bucket("filename", "/some/path")

      expect(AWS::S3).
        to have_received(:new).
        with(access_key_id: key_id, secret_access_key: access_key).
        once
    end
  end
end
