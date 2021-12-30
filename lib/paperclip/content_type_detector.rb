module Paperclip
  class ContentTypeDetector
    # The content-type detection strategy is as follows:
    #
    # 1. Blank/Empty files: If there's no filepath or the file is empty,
    #    provide a sensible default (application/octet-stream or inode/x-empty)
    #
    # 2. Calculated match: Return the first result that is found by both the
    #    `file` command and MIME::Types.
    #
    # 3. Standard types: Return the first standard (without an x- prefix) entry
    #    in MIME::Types
    #
    # 4. Experimental types: If there were no standard types in MIME::Types
    #    list, try to return the first experimental one
    #
    # 5. Raw `file` command: Just use the output of the `file` command raw, or
    #    a sensible default. This is cached from Step 2.

    EMPTY_TYPE = "inode/x-empty"
    SENSIBLE_DEFAULT = "application/octet-stream"

    def initialize(filepath)
      @filepath = filepath
    end

    # Returns a String describing the file's content type
    def detect
      if blank_name?
        SENSIBLE_DEFAULT
      elsif empty_file?
        EMPTY_TYPE
      else
        calculated_type_matches.first || type_from_file_contents.first || SENSIBLE_DEFAULT
      end.to_s
    end

    private

    def blank_name?
      @filepath.nil? || @filepath.empty?
    end

    def empty_file?
      File.exist?(@filepath) && File.size(@filepath) == 0
    end

    alias :empty? :empty_file?

    def calculated_type_matches
      possible_types & types_from_file_contents
    end

    def possible_types
      MIME::Types.type_for(@filepath).collect(&:content_type)
    end

    def types_from_file_contents
      if types_from_marcel.any?
        types_from_marcel
      else
        [type_from_file_command]
      end
    rescue Errno::ENOENT => e
      Paperclip.log("Error while determining content type: #{e}")
      []
    end

    def types_from_marcel
      @types_from_marcel ||= File.open(@filepath) do |file|
        Marcel::Magic.all_by_magic(file).map(&:type)
      end
    end

    def type_from_file_command
      @type_from_file_command ||=
        FileCommandContentTypeDetector.new(@filepath).detect
    end
  end
end
