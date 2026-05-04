# frozen_string_literal: true

module Paperclip
  # @deprecated Will be removed in Paperclip 8.0. Use +Paperclip::ContentTypeDetector+ instead.
  class FileCommandContentTypeDetector
    # @deprecated Will be removed in Paperclip 8.0.
    SENSIBLE_DEFAULT = "application/octet-stream"

    # @deprecated Will be removed in Paperclip 8.0. Use +Paperclip::ContentTypeDetector+ instead.
    def initialize(filename)
      warn_deprecation
      @filename = filename
    end

    # @deprecated Will be removed in Paperclip 8.0. Use +Paperclip::ContentTypeDetector+ instead.
    def detect
      warn_deprecation
      Paperclip::Commands::UnixFile.detect_content_type(@filename) || SENSIBLE_DEFAULT
    end

    private

    def warn_deprecation
      Paperclip.deprecator.warn("Paperclip::FileCommandContentTypeDetector has been replaced by Paperclip::ContentTypeDetector.")
    end
  end
end
