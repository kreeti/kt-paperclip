# frozen_string_literal: true

require "spec_helper"

describe Paperclip::Commands::ImageMagick::VersionDetector do
  before do
    @original_imagemagick_version = Paperclip.options[:imagemagick_version]
    @original_command_path = Paperclip.options[:command_path]
  end

  after do
    described_class.remove_instance_variable(:@detected_version) if described_class.instance_variable_defined?(:@detected_version)
    Paperclip.options[:imagemagick_version] = @original_imagemagick_version
    Paperclip.options[:command_path] = @original_command_path
  end

  describe ".detected_version" do
    context "when ImageMagick 7 is installed" do
      before do
        im7_cmd = double(run: "Version: ImageMagick 7.1.1-38 Q16-HDRI x86_64")
        allow(Terrapin::CommandLine).to receive(:new)
          .with("magick", "-version", hash_including(swallow_stderr: true))
          .and_return(im7_cmd)
      end

      it "returns 7" do
        expect(described_class.detected_version).to eq(7)
      end
    end

    context "when only ImageMagick 6 is installed" do
      before do
        allow(Terrapin::CommandLine).to receive(:new)
          .with("magick", "-version", hash_including(swallow_stderr: true))
          .and_raise(Terrapin::CommandNotFoundError.new("magick"))

        im6_cmd = double(run: "Version: ImageMagick 6.9.12-98 Q16 x86_64")
        allow(Terrapin::CommandLine).to receive(:new)
          .with("convert", "-version", hash_including(swallow_stderr: true))
          .and_return(im6_cmd)
      end

      it "returns 6" do
        expect(described_class.detected_version).to eq(6)
      end
    end

    context "when magick -version exits with non-zero status" do
      before do
        allow(Terrapin::CommandLine).to receive(:new)
          .with("magick", "-version", hash_including(swallow_stderr: true))
          .and_raise(Terrapin::ExitStatusError.new("magick"))

        im6_cmd = double(run: "Version: ImageMagick 6.9.12-98 Q16 x86_64")
        allow(Terrapin::CommandLine).to receive(:new)
          .with("convert", "-version", hash_including(swallow_stderr: true))
          .and_return(im6_cmd)
      end

      it "falls back to IM6" do
        expect(described_class.detected_version).to eq(6)
      end
    end

    context "when ImageMagick is not installed at all" do
      before do
        allow(Terrapin::CommandLine).to receive(:new)
          .and_raise(Terrapin::CommandNotFoundError.new("not found"))
      end

      it "returns nil" do
        expect(described_class.detected_version).to be_nil
      end
    end

    context "when a non-ImageMagick 'magick' binary exists" do
      before do
        non_im_cmd = double(run: "Some Other Program v1.0")
        allow(Terrapin::CommandLine).to receive(:new)
          .with("magick", "-version", hash_including(swallow_stderr: true))
          .and_return(non_im_cmd)

        im6_cmd = double(run: "Version: ImageMagick 6.9.12-98 Q16 x86_64")
        allow(Terrapin::CommandLine).to receive(:new)
          .with("convert", "-version", hash_including(swallow_stderr: true))
          .and_return(im6_cmd)
      end

      it "falls through to IM6 detection" do
        expect(described_class.detected_version).to eq(6)
      end
    end

    it "caches the detection result" do
      version1 = described_class.detected_version
      version2 = described_class.detected_version
      expect(version1).to eq(version2)
    end
  end
end

describe Paperclip::Commands::ImageMagick do
  describe ".magick_command?" do
    before do
      @original_imagemagick_version = Paperclip.options[:imagemagick_version]
    end

    after do
      Paperclip.options[:imagemagick_version] = @original_imagemagick_version
    end

    context "with auto-detection returning 7" do
      before do
        allow(Paperclip::Commands::ImageMagick::VersionDetector).to receive(:detected_version).and_return(7)
        Paperclip.options[:imagemagick_version] = nil
      end

      it "returns true" do
        expect(described_class.send(:magick_command?)).to be true
      end
    end

    context "with auto-detection returning 6" do
      before do
        allow(Paperclip::Commands::ImageMagick::VersionDetector).to receive(:detected_version).and_return(6)
        Paperclip.options[:imagemagick_version] = nil
      end

      it "returns false" do
        expect(described_class.send(:magick_command?)).to be false
      end
    end

    context "with auto-detection returning nil" do
      before do
        allow(Paperclip::Commands::ImageMagick::VersionDetector).to receive(:detected_version).and_return(nil)
        Paperclip.options[:imagemagick_version] = nil
      end

      it "returns false" do
        expect(described_class.send(:magick_command?)).to be false
      end
    end

    context "with user override 7" do
      before do
        Paperclip.options[:imagemagick_version] = 7
      end

      it "returns true regardless of detection" do
        expect(described_class.send(:magick_command?)).to be true
      end
    end

    context "with user override 6" do
      before do
        Paperclip.options[:imagemagick_version] = 6
      end

      it "returns false regardless of detection" do
        expect(described_class.send(:magick_command?)).to be false
      end
    end
  end

  describe ".convert_command" do
    context "when ImageMagick 7" do
      before { allow(described_class).to receive(:magick_command?).and_return(true) }

      it "returns 'magick'" do
        expect(described_class.send(:convert_command)).to eq("magick")
      end
    end

    context "when ImageMagick 6" do
      before { allow(described_class).to receive(:magick_command?).and_return(false) }

      it "returns 'convert'" do
        expect(described_class.send(:convert_command)).to eq("convert")
      end
    end
  end

  describe ".identify_command" do
    context "when ImageMagick 7" do
      before { allow(described_class).to receive(:magick_command?).and_return(true) }

      it "returns 'magick identify'" do
        expect(described_class.send(:identify_command)).to eq("magick identify")
      end
    end

    context "when ImageMagick 6" do
      before { allow(described_class).to receive(:magick_command?).and_return(false) }

      it "returns 'identify'" do
        expect(described_class.send(:identify_command)).to eq("identify")
      end
    end
  end
end
