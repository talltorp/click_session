require "aws"

module ClickSession
  class S3Connection
    attr_reader :bucket_name

    def initialize(
      key_id = ClickSession.configuration.screenshot[:s3_key_id],
      access_key = ClickSession.configuration.screenshot[:s3_access_key],
      bucket_name = ClickSession.configuration.screenshot[:s3_bucket]
    )
      @key_id = key_id
      @access_key = access_key
      @bucket_name = bucket_name
    end

    def upload_from_filesystem_to_bucket(file_name, file_path)
      bucket.objects[file_name].write(
        Pathname.new(file_path),
        acl: :public_read
      )
    end

    private
    def bucket
      @bucket ||= s3.buckets[@bucket_name]
    end

    def s3
      @s3 ||= AWS::S3.new(
        :access_key_id => @key_id,
        :secret_access_key => @access_key
      )
    end
  end
end
