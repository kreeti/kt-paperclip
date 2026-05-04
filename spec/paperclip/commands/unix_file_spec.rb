# frozen_string_literal: true

require "spec_helper"

describe Paperclip::Commands::UnixFile do
  describe ".detect_content_type" do
    it "returns a content type based on the content of the file" do
      tempfile = Tempfile.new("something")
      tempfile.write("This is a file.")
      tempfile.rewind

      assert_equal "text/plain", described_class.detect_content_type(tempfile.path)

      tempfile.close
    end

    it "returns a sensible default when the file command is missing" do
      allow(described_class).to receive(:run_file_command).and_raise(Terrapin::CommandLineError.new)
      assert_nil described_class.detect_content_type("/path/to/something")
    end

    it "returns a sensible default when run returns nil" do
      allow(described_class).to receive(:run_file_command).and_return(nil)
      assert_nil described_class.detect_content_type("windows")
    end

    it "parses old-style file command output" do
      allow(described_class).to receive(:run_file_command).and_return("text/html charset=us-ascii")
      expect(described_class.detect_content_type("html")).to eq("text/html")
    end

    it "parses new-style file command output" do
      allow(described_class).to receive(:run_file_command).and_return("text/html; charset=us-ascii")
      expect(described_class.detect_content_type("html")).to eq("text/html")
    end
  end
end
