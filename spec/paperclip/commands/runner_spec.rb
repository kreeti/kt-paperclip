# frozen_string_literal: true

require "spec_helper"

describe Paperclip::Commands::Runner do
  describe ".run" do
    after do
      Paperclip.options[:log_command] = true
    end

    it "runs the command with Terrapin" do
      Paperclip.options[:log_command] = false
      expect(Terrapin::CommandLine).to receive(:new)
        .with("convert", "stuff", {})
        .and_return(double(run: nil))
      described_class.run("convert", nil, "stuff")
    end

    it "does not raise errors when doing a lot of running" do
      100.times do |x|
        described_class.run("echo", nil, x.to_s)
      end
    end

    it "uses deprecated command_path option when no explicit path given" do
      Paperclip.options[:log_command] = false
      Paperclip.options[:command_path] = "/opt/my_app/bin"
      expect(Terrapin::CommandLine).to receive(:new)
        .with("convert", "stuff", {})
        .and_return(double(run: nil))
      described_class.run("convert", nil, "stuff")
    ensure
      Paperclip.options[:command_path] = nil
    end

    it "passes the defined logger if :log_command is set" do
      Paperclip.options[:log_command] = true
      expect(Terrapin::CommandLine).to receive(:new)
        .with("convert", "stuff", hash_including(logger: Paperclip.logger))
        .and_return(double(run: nil))
      described_class.run("convert", nil, "stuff")
    end

    it "does not mutate Terrapin::CommandLine.path" do
      original_path = Terrapin::CommandLine.path
      described_class.run("echo", "/some/custom/path", "hello")
      expect(Terrapin::CommandLine.path).to eq(original_path)
    end

    context "with a path" do
      it "resolves the binary to an absolute path when executable" do
        Dir.mktmpdir do |dir|
          bin = File.join(dir, "mycmd")
          File.write(bin, "#!/bin/sh\necho ok")
          File.chmod(0o755, bin)

          expect(Terrapin::CommandLine).to receive(:new)
            .with(bin, "args", {})
            .and_return(double(run: nil))

          Paperclip.options[:log_command] = false
          described_class.run("mycmd", dir, "args")
        end
      end

      it "falls back to bare command when not found in path" do
        Paperclip.options[:log_command] = false
        expect(Terrapin::CommandLine).to receive(:new)
          .with("mycmd", "args", {})
          .and_return(double(run: nil))
        described_class.run("mycmd", "/nonexistent/dir", "args")
      end

      it "resolves multi-word commands (e.g. 'magick identify')" do
        Dir.mktmpdir do |dir|
          bin = File.join(dir, "magick")
          File.write(bin, "#!/bin/sh\necho ok")
          File.chmod(0o755, bin)

          expect(Terrapin::CommandLine).to receive(:new)
            .with("#{bin} identify", "args", {})
            .and_return(double(run: nil))

          Paperclip.options[:log_command] = false
          described_class.run("magick identify", dir, "args")
        end
      end
    end
  end
end
