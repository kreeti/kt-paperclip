module Paperclip
  class HttpUrlProxyAdapter < UriAdapter

    REGEXP = /\Ahttps?:\/\//

    def initialize(target)
      escaped = Paperclip::UrlGenerator.escape(target)
      super(URI(target == Paperclip::UrlGenerator.unescape(target) ? escaped : target))
    end

  end
end

Paperclip.io_adapters.register Paperclip::HttpUrlProxyAdapter do |target|
  String === target && target =~ Paperclip::HttpUrlProxyAdapter::REGEXP
end
