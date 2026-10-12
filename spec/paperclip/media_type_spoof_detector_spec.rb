# frozen_string_literal: true

require "spec_helper"

describe Paperclip::MediaTypeSpoofDetector do
  it "rejects a file that is named .html and identifies as PNG" do
    file = File.open(fixture_file("5k.png"))
    assert Paperclip::MediaTypeSpoofDetector.using(file, "5k.html", "image/png").spoofed?
  end

  it "does not reject a file that is named .jpg and identifies as PNG" do
    file = File.open(fixture_file("5k.png"))
    assert !Paperclip::MediaTypeSpoofDetector.using(file, "5k.jpg", "image/png").spoofed?
  end

  it "does not reject a file that is named .html and identifies as HTML" do
    file = File.open(fixture_file("empty.html"))
    assert !Paperclip::MediaTypeSpoofDetector.using(file, "empty.html", "text/html").spoofed?
  end

  it "does not reject a file that does not have a name" do
    file = File.open(fixture_file("empty.html"))
    assert !Paperclip::MediaTypeSpoofDetector.using(file, "", "text/html").spoofed?
  end

  it "does not reject a file that does have an extension" do
    file = File.open(fixture_file("empty.html"))
    assert !Paperclip::MediaTypeSpoofDetector.using(file, "data", "text/html").spoofed?
  end

  it "does not reject when the supplied file is an IOAdapter" do
    adapter = Paperclip.io_adapters.for(File.new(fixture_file("5k.png")))
    assert !Paperclip::MediaTypeSpoofDetector.using(adapter, adapter.original_filename, adapter.content_type).spoofed?
  end

  it "does not reject when the extension => content_type is in :content_type_mappings" do
    # The content is deliberately not valid PEM: a real certificate has a magic number of its own,
    # which would satisfy the check before the mapping override is ever consulted. The mapping is
    # keyed on what the *contents* detect as, which for this file is text/plain.
    file = Tempfile.open(["test", ".PEM"])
    file.puts "Certificate!"
    file.close

    adapter = Paperclip.io_adapters.for(File.new(file.path))

    begin
      Paperclip.options[:content_type_mappings] = { pem: "text/plain" }
      assert !Paperclip::MediaTypeSpoofDetector.using(adapter, adapter.original_filename, adapter.content_type).spoofed?

      # As a string.
      Paperclip.options[:content_type_mappings] = { "pem" => "text/plain" }
      assert !Paperclip::MediaTypeSpoofDetector.using(adapter, adapter.original_filename, adapter.content_type).spoofed?
    ensure
      Paperclip.options[:content_type_mappings] = {}
    end
  end

  context "file named .html and is as HTML, but we're told JPG" do
    let(:file) { File.open(fixture_file("empty.html")) }
    let(:spoofed?) { Paperclip::MediaTypeSpoofDetector.using(file, "empty.html", "image/jpg").spoofed? }

    it "rejects the file" do
      assert spoofed?
    end

    it "logs info about the detected spoof" do
      expect(Paperclip).to receive(:log).with('Content Type Spoof: Filename empty.html (image/jpg from Headers, ["text/html"] from Extension), content type discovered from file command: text/html. See documentation to allow this combination.')
      spoofed?
    end
  end

  context "GIF file named without extension, but we're told GIF" do
    let(:file) { File.open(fixture_file("animated")) }
    let(:spoofed?) do
      Paperclip::MediaTypeSpoofDetector.
        using(file, "animated", "image/gif").
        spoofed?
    end

    it "accepts the file" do
      assert !spoofed?
    end
  end

  context "GIF file named without extension, but we're told HTML" do
    let(:file) { File.open(fixture_file("animated")) }
    let(:spoofed?) do
      Paperclip::MediaTypeSpoofDetector.
        using(file, "animated", "text/html").
        spoofed?
    end

    it "rejects the file" do
      assert spoofed?
    end
  end

  it "does not reject if content_type is empty but otherwise checks out" do
    file = File.open(fixture_file("empty.html"))
    assert !Paperclip::MediaTypeSpoofDetector.using(file, "empty.html", "").spoofed?
  end

  it "does allow array as :content_type_mappings" do
    begin
      Paperclip.options[:content_type_mappings] = {
        html: ["binary", "text/html"]
      }
      file = File.open(fixture_file("empty.html"))
      spoofed = Paperclip::MediaTypeSpoofDetector.
                using(file, "empty.html", "text/html").spoofed?
      assert !spoofed
    ensure
      Paperclip.options[:content_type_mappings] = {}
    end
  end

  # https://github.com/kreeti/kt-paperclip/issues/173
  #
  # Marcel is consulted first and is given the file path as a `name:` hint, so
  # for content it cannot identify from the bytes alone (plain text, for
  # example) it falls back to the filename extension. A text file renamed to
  # wrong.jpg therefore "calculates" as image/jpeg and the spoof goes
  # undetected. 7.3.0 ran the `file` command on the bytes and rejected it.
  context "text file renamed with an image extension, and we're told JPEG" do
    let(:file) do
      tempfile = Tempfile.new(["wrong", ".jpg"])
      tempfile.write("WRONG IMAGE")
      tempfile.close
      File.open(tempfile.path)
    end

    let(:spoofed?) do
      Paperclip::MediaTypeSpoofDetector.
        using(file, "wrong.jpg", "image/jpeg").
        spoofed?
    end

    it "rejects the file" do
      assert spoofed?
    end
  end

  # An SVG that opens with an XML declaration has no magic number of its own -- Marcel resolves it
  # to application/xml, whose media type is "application", not "image". The `file` command knows
  # better, so both sources have to be consulted before calling a file a spoof.
  context "SVG file carrying an XML declaration, told SVG" do
    let(:file) do
      tempfile = Tempfile.new(["drawing", ".svg"])
      tempfile.write(%(<?xml version="1.0"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"/>\n))
      tempfile.close
      File.open(tempfile.path)
    end

    let(:spoofed?) do
      Paperclip::MediaTypeSpoofDetector.
        using(file, "drawing.svg", "image/svg+xml").
        spoofed?
    end

    it "accepts the file" do
      assert !spoofed?
    end
  end

  context "when the `file` command is unavailable" do
    before do
      allow(Paperclip::Commands::UnixFile).
        to receive(:detect_content_type).and_return(nil)
    end

    it "still rejects a file whose magic number contradicts the supplied type" do
      file = File.open(fixture_file("empty.html"))
      assert Paperclip::MediaTypeSpoofDetector.using(file, "evil.jpg", "image/jpeg").spoofed?
    end

    it "does not reject a file whose contents cannot be identified at all" do
      tempfile = Tempfile.new(["notes", ".txt"])
      tempfile.write("nothing to see here")
      tempfile.close

      file = File.open(tempfile.path)
      assert !Paperclip::MediaTypeSpoofDetector.using(file, "notes.txt", "text/plain").spoofed?
    end
  end

  context "#calculated_content_type" do
    let(:file) { File.new(fixture_file("empty.html")) }
    let(:detector) { Paperclip::MediaTypeSpoofDetector.new(file, "html", "") }

    it "determines the type from the file contents" do
      expect(detector.send(:calculated_content_type)).to eq("text/html")
    end
  end
end
