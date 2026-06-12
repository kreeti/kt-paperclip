# frozen_string_literal: true

module Paperclip
  module Commands
    module ImageMagick
      module VersionDetector
        extend self

        # Returns 6, 7, or nil (not installed)
        def detected_version
          return @detected_version if defined?(@detected_version)

          @detected_version = detect
        end

        private

        def detect
          return 7 if valid?("magick")
          return 6 if valid?("convert")

          nil
        end

        def valid?(command)
          run(command).to_s.include?("ImageMagick")
        end

        def run(command)
          Paperclip::Commands::Runner.run(command, path, "-version", {}, swallow_stderr: true)
        rescue Terrapin::CommandLineError
          nil
        end

        def path
          Paperclip::Commands::ImageMagick.imagemagick_path
        end
      end
    end
  end
end
