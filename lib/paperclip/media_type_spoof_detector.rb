# frozen_string_literal: true

module Paperclip
  class MediaTypeSpoofDetector
    def self.using(file, name, content_type)
      new(file, name, content_type)
    end

    def initialize(file, name, content_type)
      @file = file
      @name = name
      @content_type = content_type || ""
    end

    def spoofed?
      if has_name? && media_type_mismatch? && mapping_override_mismatch?
        Paperclip.log("Content Type Spoof: Filename #{File.basename(@name)} (#{supplied_content_type} from Headers, #{content_types_from_name.map(&:to_s)} from Extension), content type discovered from file command: #{calculated_content_type}. See documentation to allow this combination.")
        true
      else
        false
      end
    end

    private

    def has_name?
      @name.present?
    end

    def has_extension?
      File.extname(@name).present?
    end

    def media_type_mismatch?
      extension_type_mismatch? || calculated_type_mismatch?
    end

    def extension_type_mismatch?
      supplied_media_type.present? &&
        has_extension? &&
        !media_types_from_name.include?(supplied_media_type)
    end

    def calculated_type_mismatch?
      return false if supplied_media_type.blank?
      # Fast path: the magic number already supports the supplied type, no shell out needed.
      return false if supplied_type_consistent_with?(type_from_magic)
      # The bytes told us nothing at all, so there is nothing to contradict the supplied type.
      return false if calculated_content_types.empty?

      !supplied_type_consistent_with?(type_from_file_command)
    end

    # The supplied type is supported by the bytes if it shares their media type, or if it is a
    # specialization of what the bytes resolved to: image/svg+xml is a child of application/xml,
    # which is all the magic number of an SVG with an XML declaration can tell us.
    def supplied_type_consistent_with?(type)
      return false if type.blank?

      type.include?(supplied_media_type) ||
        !!Marcel::Magic.child?(supplied_content_type, type)
    end

    def mapping_override_mismatch?
      (Array(mapped_content_type) & calculated_content_types).empty?
    end

    def supplied_content_type
      @content_type
    end

    def supplied_media_type
      @content_type.split("/").first
    end

    def content_types_from_name
      @content_types_from_name ||= MIME::Types.type_for(@name)
    end

    def media_types_from_name
      @media_types_from_name ||= content_types_from_name.collect(&:media_type)
    end

    # Every type the file's *contents* resolve to. The filename is deliberately never consulted
    # here -- trusting it is what let a renamed file pass this check (kreeti/kt-paperclip#173).
    def calculated_content_types
      @calculated_content_types ||=
        # Both sources return nil, never a blank string, when they come up empty.
        [type_from_magic, type_from_file_command].compact.uniq
    end

    def calculated_content_type
      @calculated_content_type ||= calculated_content_types.first.to_s
    end

    # Note the absence of a `name:` argument. Marcel lets the filename decide when the bytes carry
    # no magic number of their own, which is exactly what spoof detection must not allow.
    def type_from_magic
      return @type_from_magic if defined?(@type_from_magic)

      type = Marcel::MimeType.for(Pathname.new(@file.path))
      # Marcel::MimeType returns 'application/octet-stream' if it can't find a valid type.
      @type_from_magic = type == ContentTypeDetector::SENSIBLE_DEFAULT ? nil : type
    rescue Errno::ENOENT => e
      Paperclip.log("Error while determining content type: #{e}")
      @type_from_magic = nil
    end

    def type_from_file_command
      return @type_from_file_command if defined?(@type_from_file_command)

      @type_from_file_command = Commands::UnixFile.detect_content_type(@file.path)
    end

    def mapped_content_type
      content_type_mappings = Paperclip.options[:content_type_mappings]
      content_type_mappings[filename_extension] || content_type_mappings[filename_extension.to_s]
    end

    def filename_extension
      File.extname(@name.to_s.downcase).sub(/^\./, "").to_sym
    end
  end
end
