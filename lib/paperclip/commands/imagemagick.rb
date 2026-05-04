# frozen_string_literal: true

module Paperclip
  module Commands
    module ImageMagick
      extend self

      def convert(arguments = nil, interpolation_values = {}, local_options = {})
        run(convert_command, imagemagick_path, arguments, interpolation_values, local_options)
      end

      def identify(arguments = nil, interpolation_values = {}, local_options = {})
        run(identify_command, imagemagick_path, arguments, interpolation_values, local_options)
      end

      def imagemagick_path
        Paperclip.options[:imagemagick_path]
      end

      private

      def run(command, path = nil, arguments = nil, interpolation_values = {}, local_options = {})
        Runner.run(command, path || imagemagick_path, arguments, interpolation_values, local_options)
      rescue Terrapin::CommandNotFoundError
        raise Errors::CommandNotFoundError.new("Could not run the `#{command}` command. Please install ImageMagick.")
      end

      # Returns true if ImageMagick 7 is in use (either detected or forced via config)
      def magick_command?
        version = Paperclip.options[:imagemagick_version]&.to_i ||
                  VersionDetector.detected_version
        !version.nil? && version >= 7
      end

      def convert_command
        magick_command? ? "magick" : "convert"
      end

      def identify_command
        magick_command? ? "magick identify" : "identify"
      end
    end
  end
end
