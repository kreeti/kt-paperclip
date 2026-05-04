# frozen_string_literal: true

require "spec_helper"

describe Paperclip::Processor do
  it "instantiates and call #make when sent #make to the class" do
    processor = double
    expect(processor).to receive(:make)
    expect(Paperclip::Processor).to receive(:new).with(:one, :two, :three).and_return(processor)
    Paperclip::Processor.make(:one, :two, :three)
  end

  context "Calling #convert" do
    it "delegates to Commands::ImageMagick.convert" do
      expect(Paperclip::Commands::ImageMagick).to receive(:convert).with("stuff", {})
      Paperclip::Processor.new("filename").convert("stuff")
    end
  end

  context "Calling #identify" do
    it "delegates to Commands::ImageMagick.identify" do
      expect(Paperclip::Commands::ImageMagick).to receive(:identify).with("stuff", {})
      Paperclip::Processor.new("filename").identify("stuff")
    end
  end
end
