# frozen_string_literal: true

require "spec_helper"

describe Paperclip::GeometryParser do
  it "identifies an image and extract its dimensions with no orientation" do
    output = Paperclip::GeometryParser.new("434x73").make

    assert_equal Paperclip::Geometry.new(434, 73), output
  end

  it "identifies an image and extract its dimensions with an empty orientation" do
    output = Paperclip::GeometryParser.new("434x73,").make

    assert_equal Paperclip::Geometry.new(434, 73), output
  end

  it "identifies an image and extract its dimensions and orientation" do
    output = Paperclip::GeometryParser.new("300x200,6").make

    assert_equal Paperclip::Geometry.new(300, 200, nil, 6), output
  end

  it "identifies an image and extract its dimensions and modifier" do
    output = Paperclip::GeometryParser.new("64x64#").make

    assert_equal Paperclip::Geometry.new(64, 64, "#"), output
  end

  it "identifies an image and extract its dimensions, orientation, and modifier" do
    output = Paperclip::GeometryParser.new("100x50,7>").make

    assert_equal Paperclip::Geometry.new(100, 50, ">", 7), output
  end
end
