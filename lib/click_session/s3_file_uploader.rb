module ClickSession
  class S3FileUploader
    def initialize(s3_connection = S3Connection.new)
      @s3_connection = s3_connection
    end

    def upload_file(file_name)
      @s3_connection.upload_from_filesystem_to_bucket(
          file_name,
          file_path_for(file_name)
        )
      uploaded_file_path_for(file_name)
    end
    
    private
    def file_path_for(file_name)
      "#{Rails.root}/tmp/#{file_name}"
    end

    def uploaded_file_path_for(file_name)
      "https://s3.amazonaws.com/#{@s3_connection.bucket_name}/#{file_name}"
    end
  end
end