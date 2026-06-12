# frozen_string_literal: true

module Paperclip
  module Commands
    module ImageMagick
      module GeometryParser
        extend self

        FORMAT = /\b(\d*)x?(\d*)\b(?:,(\d?))?(@>|>@|[><#@%^!])?/i.freeze

        # Runs `magick identify` and returns a Paperclip::Geometry
        def detect(file)
          parse(fetch(file))
        end
        alias_method :from_file, :detect

        # Parses a "WxH,O" string into a Paperclip::Geometry
        def parse(string)
          return unless (match = string&.strip&.match(FORMAT))

          Paperclip::Geometry.new(
            width: match[1],
            height: match[2],
            orientation: match[3],
            modifier: match[4]
          )
        end

        private

        def fetch(file)
          filepath = path(file)
          raise_error("Cannot find the geometry of a file with a blank name") if filepath.blank?

          str = Paperclip::Commands::ImageMagick.identify(
            "-format '%wx%h,#{orientation}' :file",
            { file: "#{filepath}[0]" },
            { swallow_stderr: true }
          ).presence

          raise_error unless str

          str
        rescue Terrapin::ExitStatusError
          raise_error
        end

        def path(file)
          file.respond_to?(:path) ? file.path : file
        end

        def orientation
          Paperclip.options[:use_exif_orientation] ? "%[exif:orientation]" : "1"
        end

        def raise_error(message = nil)
          message ||= "Could not identify image size"
          raise Errors::NotIdentifiedByImageMagickError.new(message)
        end
      end
    end
  end
end
