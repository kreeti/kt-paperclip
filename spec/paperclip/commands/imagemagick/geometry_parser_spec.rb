# frozen_string_literal: true

require "spec_helper"

describe Paperclip::Commands::ImageMagick::GeometryParser do
  describe ".from_file" do
    it "identifies an image and extracts its dimensions" do
      file = fixture_file("5k.png")
      output = described_class.from_file(file)
      expect(output).to be_a(Paperclip::Geometry)
    end

    it "identifies an image and extracts its dimensions and orientation" do
      file = fixture_file("rotated.jpg")
      output = described_class.from_file(file)
      expect(output).to be_a(Paperclip::Geometry)
    end

    it "avoids reading EXIF orientation if so configured" do
      Paperclip.options[:use_exif_orientation] = false
      file = fixture_file("rotated.jpg")
      output = described_class.from_file(file)
      expect(output).to be_a(Paperclip::Geometry)
    ensure
      Paperclip.options[:use_exif_orientation] = true
    end

    it "delegates to Commands::ImageMagick.identify" do
      file = fixture_file("5k.png")
      expect(Paperclip::Commands::ImageMagick).to receive(:identify)
        .with(anything, anything, anything)
        .and_return("434x66,1")
      described_class.from_file(file)
    end

    it "raises an exception with a message when the file is not an image" do
      file = fixture_file("text.txt")

      expect do
        described_class.from_file(file)
      end.to raise_error(Paperclip::Errors::NotIdentifiedByImageMagickError, "Could not identify image size")
    end
  end

  describe ".parse" do
    it "extracts dimensions with no orientation" do
      geo = described_class.parse("434x73")
      expect(geo).to eq Paperclip::Geometry.new(width: 434, height: 73)
    end

    it "extracts dimensions with an empty orientation" do
      geo = described_class.parse("434x73,")
      expect(geo).to eq Paperclip::Geometry.new(width: 434, height: 73)
      expect(geo.orientation).to eq(0)
    end

    it "extracts dimensions and orientation" do
      geo = described_class.parse("300x200,6")
      expect(geo).to eq Paperclip::Geometry.new(width: 300, height: 200, orientation: 6)
      expect(geo.orientation).to eq(6)
    end

    it "extracts dimensions and modifier" do
      geo = described_class.parse("64x64#")
      expect(geo).to eq Paperclip::Geometry.new(width: 64, height: 64, modifier: "#")
      expect(geo.orientation).to eq(0)
    end

    it "extracts dimensions, orientation, and modifier" do
      geo = described_class.parse("100x50,7>")
      expect(geo).to eq Paperclip::Geometry.new(width: 100, height: 50, modifier: ">", orientation: 7)
      expect(geo.orientation).to eq(7)
    end

    it "returns nil for nil input" do
      expect(described_class.parse(nil)).to be_nil
    end
  end
end
