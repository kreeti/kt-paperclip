# frozen_string_literal: true

module Paperclip
  class DataUriAdapter < StringioAdapter
    def self.register
      Paperclip.io_adapters.register self do |target|
        String === target && target =~ REGEXP
      end
    end

    REGEXP = /\Adata:([-\w]+\/[-\w\+\.]+)?;base64,/.freeze

    def initialize(target_uri, options = {})
      super(extract_target(target_uri), options)
    end

    private

    def extract_target(uri)
      match = uri.match(REGEXP)
      StringIO.new(Base64.decode64(match ? match.post_match : ""))
    end
  end
end
