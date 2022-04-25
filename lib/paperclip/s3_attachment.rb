module Paperclip
  # The Attachment class manages the files for a given attachment. It saves
  # when the model saves, deletes when the model is destroyed, and processes
  # the file upon assignment.
  class S3Attachment < Attachment
    include Paperclip::Storage::S3

    def initialize(name, instance, options = {})
      super

      @s3_options     = @options[:s3_options] || {}
      @s3_permissions = set_permissions(@options[:s3_permissions])
      @s3_protocol    = @options[:s3_protocol] || ""
      @s3_metadata = @options[:s3_metadata] || {}
      @s3_headers = {}
      merge_s3_headers(@options[:s3_headers], @s3_headers, @s3_metadata)

      @s3_storage_class = set_storage_class(@options[:s3_storage_class])

      @s3_server_side_encryption = "AES256"
      @s3_server_side_encryption = false if @options[:s3_server_side_encryption].blank?
      @s3_server_side_encryption = @options[:s3_server_side_encryption] if @s3_server_side_encryption

      unless @options[:url].to_s.match(/\A:s3.*url\z/) || @options[:url] == ":asset_host"
        @options[:path] = path_option.gsub(/:url/, @options[:url]).sub(/\A:rails_root\/public\/system/, "")
        @options[:url]  = ":s3_path_url"
      end
      @options[:url] = @options[:url].inspect if @options[:url].is_a?(Symbol)

      @http_proxy = @options[:http_proxy] || nil

      @use_accelerate_endpoint = @options[:use_accelerate_endpoint]
    end

  end
end
