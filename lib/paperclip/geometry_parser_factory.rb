# frozen_string_literal: true

module Paperclip
  # @deprecated Will be removed in Paperclip 8.0. Use +Paperclip::Commands::ImageMagick::GeometryParser+ instead.
  class GeometryParser
    # @deprecated Will be removed in Paperclip 8.0. Use +Paperclip::Commands::ImageMagick::GeometryParser::FORMAT+ instead.
    FORMAT = Paperclip::Commands::ImageMagick::GeometryParser::FORMAT

    # @deprecated Will be removed in Paperclip 8.0. Use +Paperclip::Commands::ImageMagick::GeometryParser+ instead.
    def initialize(string)
      warn_deprecation
      @string = string
    end

    # @deprecated Will be removed in Paperclip 8.0. Use +Paperclip::Commands::ImageMagick::GeometryParser+ instead.
    def make
      warn_deprecation
      Paperclip::Commands::ImageMagick::GeometryParser.parse(@string)
    end

    private

    def warn_deprecation
      Paperclip.deprecator.warn("Paperclip::GeometryParser has been replaced by Paperclip::Commands::ImageMagick::GeometryParser")
    end
  end
end
