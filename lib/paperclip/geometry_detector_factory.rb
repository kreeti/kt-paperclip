# frozen_string_literal: true

module Paperclip
  # @deprecated Will be removed in Paperclip 8.0. Use +Paperclip::Commands::ImageMagick::GeometryParser+ instead.
  class GeometryDetector
    # @deprecated Will be removed in Paperclip 8.0. Use +Paperclip::Commands::ImageMagick::GeometryParser+ instead.
    def initialize(file)
      warn_deprecation
      @file = file
      raise Errors::NotIdentifiedByImageMagickError.new("Cannot find the geometry of a file with a blank name") if @file.blank?
    end

    # @deprecated Will be removed in Paperclip 8.0. Use +Paperclip::Commands::ImageMagick::GeometryParser+ instead.
    def make
      warn_deprecation
      Paperclip::Commands::ImageMagick::GeometryParser.from_file(@file)
    end

    private

    def warn_deprecation
      Paperclip.deprecator.warn("Paperclip::GeometryDetector has been replaced by Paperclip::Commands::ImageMagick::GeometryParser")
    end
  end
end
