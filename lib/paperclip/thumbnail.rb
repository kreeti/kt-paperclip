module Paperclip
  # Handles thumbnailing images that are uploaded.
  class Thumbnail < Processor
    attr_accessor :current_geometry, :target_geometry, :format, :whiny, :convert_options,
                  :source_file_options, :animated, :auto_orient, :frame_index

    # List of formats that we need to preserve animation
    ANIMATED_FORMATS = %w(gif png webp).freeze
    MULTI_FRAME_FORMATS = %w(.mkv .avi .mp4 .mov .mpg .mpeg .gif .png .webp).freeze

    # Creates a Thumbnail object set to work on the +file+ given. It
    # will attempt to transform the image into one defined by +target_geometry+
    # which is a "WxH"-style string. +format+ will be inferred from the +file+
    # unless specified. Thumbnail creation will raise no errors unless
    # +whiny+ is true (which it is, by default. If +convert_options+ is
    # set, the options will be appended to the convert command upon image conversion
    #
    # Options include:
    #
    #   +geometry+ - the desired width and height of the thumbnail (required)
    #   +file_geometry_parser+ - an object with a method named +from_file+ that takes an image file and produces its geometry and a +transformation_to+. Defaults to Paperclip::Geometry
    #   +string_geometry_parser+ - an object with a method named +parse+ that takes a string and produces an object with +width+, +height+, and +to_s+ accessors. Defaults to Paperclip::Geometry
    #   +source_file_options+ - flags passed to the +convert+ command that influence how the source file is read
    #   +convert_options+ - flags passed to the +convert+ command that influence how the image is processed
    #   +whiny+ - whether to raise an error when processing fails. Defaults to true
    #   +format+ - the desired filename extension
    #   +animated+ - whether to merge all the layers in the image. Defaults to true
    #   +frame_index+ - the frame index of the source file to render as the thumbnail
    def initialize(file, options = {}, attachment = nil)
      super

      geometry             = options[:geometry].to_s
      @crop                = geometry[-1, 1] == "#"
      @target_geometry     = options.fetch(:string_geometry_parser, Geometry).parse(geometry)
      @current_geometry    = options.fetch(:file_geometry_parser, Geometry).from_file(@file)
      @source_file_options = options[:source_file_options]
      @convert_options     = options[:convert_options]
      @whiny               = options.fetch(:whiny, true)
      @format              = options[:format]
      @animated            = options.fetch(:animated, true)
      @auto_orient         = options.fetch(:auto_orient, true)
      @current_geometry.auto_orient if @auto_orient && @current_geometry.respond_to?(:auto_orient)
      @source_file_options = @source_file_options.split(/\s+/) if @source_file_options.respond_to?(:split)
      @convert_options     = @convert_options.split(/\s+/)     if @convert_options.respond_to?(:split)

      @current_format      = File.extname(@file.path)
      @basename            = File.basename(@file.path, @current_format)
      @frame_index         = multi_frame_format? ? options.fetch(:frame_index, 0) : 0
    end

    # Returns true if the +target_geometry+ is meant to crop.
    def crop?
      @crop
    end

    # Returns true if the image is meant to make use of additional convert options.
    def convert_options?
      !@convert_options.nil? && !@convert_options.empty?
    end

    # Performs the conversion of the +file+ into a thumbnail. Returns the Tempfile
    # that contains the new image.
    def make
      src = @file
      filename = [@basename, @format ? ".#{@format}" : ""].join
      dst = TempfileFactory.new.generate(filename)

      if animated? && (@format == :png || !@format && identified_as_apng?)
        # With ImageMagick < 7.0.11-13, using apng: prefix is not sufficient to output animated PNGs:
        # https://github.com/ImageMagick/ImageMagick/issues/3468
        temp_dst = TempfileFactory.new.generate("#{@basename}.apng")
      end

      begin
        parameters = []
        parameters << source_file_options
        parameters << ":source"
        parameters << transformation_command
        parameters << convert_options
        parameters << ":dest"

        parameters = parameters.flatten.compact.join(" ").strip.squeeze(" ")

        source_prefix = 'apng:' if identified_as_apng?
        frame = "[#{@frame_index}]" unless animated?

        convert(
          parameters,
          source: "#{source_prefix}#{File.expand_path(src.path)}#{frame}",
          dest: File.expand_path((temp_dst || dst).path)
        )

        if temp_dst
          IO.copy_stream(temp_dst.path, dst)
          dst.rewind
          temp_dst.unlink
        end
      rescue Terrapin::ExitStatusError => e
        if @whiny
          message = "There was an error processing the thumbnail for #{@basename}:\n" + e.message
          raise Paperclip::Error, message
        end
      rescue Terrapin::CommandNotFoundError => e
        raise Paperclip::Errors::CommandNotFoundError.new("Could not run the `convert` command. Please install ImageMagick.")
      end

      dst
    end

    # Returns the command ImageMagick's +convert+ needs to transform the image
    # into the thumbnail.
    def transformation_command
      scale, crop = @current_geometry.transformation_to(@target_geometry, crop?)
      trans = []
      trans << "-coalesce" if animated?
      trans << "-auto-orient" if auto_orient
      trans << "-resize" << %["#{scale}"] unless scale.nil? || scale.empty?
      trans << "-crop" << %["#{crop}"] << "+repage" if crop
      trans << '-layers "optimize"' if animated?
      trans
    end

    protected

    def multi_frame_format?
      MULTI_FRAME_FORMATS.include? @current_format
    end

    def animated?
      @animated && (ANIMATED_FORMATS.include?(@format.to_s) || @format.blank?) && identified_as_animated?
    end

    # Return true if ImageMagick's +identify+ returns an animated format
    def identified_as_animated?
      if @identified_as_animated.nil?
        @identified_as_animated = ANIMATED_FORMATS.include? identified_as
      end
      @identified_as_animated
    rescue Terrapin::ExitStatusError => e
      raise Paperclip::Error, "There was an error running `identify` for #{@basename}" if @whiny
    rescue Terrapin::CommandNotFoundError => e
      raise Paperclip::Errors::CommandNotFoundError.new("Could not run the `identify` command. Please install ImageMagick.")
    end

    def identified_as_apng?
      if @identified_as_apng.nil?
        @identified_as_apng = File.extname(@file.path) == '.png' || identified_as == 'png'
        @identified_as_apng &&= identify("-format %m apng::file", file: @file.path).to_s.downcase.strip.match?(/\A(apng){2,}/)
      end
      @identified_as_apng
    end

    def identified_as
      @identified_as ||= identify("-format %m :file", file: "#{@file.path}[0]").to_s.downcase.strip
    end
  end
end
