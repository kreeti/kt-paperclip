# frozen_string_literal: true

require "spec_helper"

describe Paperclip::Commands::ImageMagick do
  before do
    Paperclip.options[:log_command] = false
  end

  after do
    Paperclip.options[:log_command] = true
  end

  describe ".convert" do
    context "with ImageMagick 6" do
      before do
        allow(described_class).to receive(:convert_command).and_return("convert")
        allow(described_class).to receive(:imagemagick_path).and_return(nil)
      end

      it "runs the convert command with Terrapin" do
        expect(Terrapin::CommandLine).to receive(:new).with("convert", "stuff", {}).and_return(double(run: nil))
        described_class.convert("stuff")
      end

      it "passes interpolation values through" do
        cmd = double
        expect(Terrapin::CommandLine).to receive(:new).with("convert", ":source :dest", {}).and_return(cmd)
        expect(cmd).to receive(:run).with({ source: "a.jpg", dest: "b.jpg" })
        described_class.convert(":source :dest", { source: "a.jpg", dest: "b.jpg" })
      end
    end

    context "with ImageMagick 7" do
      before do
        allow(described_class).to receive(:convert_command).and_return("magick")
        allow(described_class).to receive(:imagemagick_path).and_return(nil)
      end

      it "runs the magick command with Terrapin" do
        expect(Terrapin::CommandLine).to receive(:new).with("magick", "stuff", {}).and_return(double(run: nil))
        described_class.convert("stuff")
      end
    end
  end

  describe ".identify" do
    context "with ImageMagick 6" do
      before do
        allow(described_class).to receive(:identify_command).and_return("identify")
        allow(described_class).to receive(:imagemagick_path).and_return(nil)
      end

      it "runs the identify command with Terrapin" do
        expect(Terrapin::CommandLine).to receive(:new).with("identify", "stuff", {}).and_return(double(run: nil))
        described_class.identify("stuff")
      end
    end

    context "with ImageMagick 7" do
      before do
        allow(described_class).to receive(:identify_command).and_return("magick identify")
        allow(described_class).to receive(:imagemagick_path).and_return(nil)
      end

      it "runs the magick identify command with Terrapin" do
        expect(Terrapin::CommandLine).to receive(:new).with("magick identify", "stuff", {}).and_return(double(run: nil))
        described_class.identify("stuff")
      end
    end
  end
end
