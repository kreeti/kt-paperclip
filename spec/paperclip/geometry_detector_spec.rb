# frozen_string_literal: true

require "spec_helper"

describe Paperclip::GeometryDetector do
  it "identifies an image and extract its dimensions" do
    file = fixture_file("5k.png")
    output = Paperclip::GeometryDetector.new(file).make

    expect(output).to eq Paperclip::Geometry.new(434, 66)
  end

  it "identifies an image and extract its dimensions and orientation" do
    file = fixture_file("rotated.jpg")
    output = Paperclip::GeometryDetector.new(file).make

    expect(output).to eq Paperclip::Geometry.new(300, 200, nil, 6)
  end

  it "avoids reading EXIF orientation if so configured" do
    Paperclip.options[:use_exif_orientation] = false
    file = fixture_file("rotated.jpg")
    output = Paperclip::GeometryDetector.new(file).make

    expect(output).to eq Paperclip::Geometry.new(300, 200, nil, 1)
  ensure
    Paperclip.options[:use_exif_orientation] = true
  end

  it "raises an exception with a message when the file is not an image" do
    file = fixture_file("text.txt")
    detector = Paperclip::GeometryDetector.new(file)

    expect do
      detector.make
    end.to raise_error(Paperclip::Errors::NotIdentifiedByImageMagickError, "Could not identify image size")
  end
end
