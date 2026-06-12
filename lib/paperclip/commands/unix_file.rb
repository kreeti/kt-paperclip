# frozen_string_literal: true

module Paperclip
  module Commands
    module UnixFile
      extend self

      # Returns a normalized content type value, otherwise nil.
      def detect_content_type(file)
        type = run_file_command(file)
        return if type.blank? || type.match(/\(.*?\)/)

        type.split(/[:;\s]+/)[0].strip
      rescue Terrapin::CommandLineError => e
        Paperclip.log("Error while determining content type: #{e}")
        nil
      end

      private

      def run_file_command(file)
        Runner.run("file", Paperclip.options[:file_command_path], "-b --mime :file", { file: file })
      rescue Terrapin::CommandLineError
        nil
      end
    end
  end
end
