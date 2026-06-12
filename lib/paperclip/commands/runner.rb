# frozen_string_literal: true

module Paperclip
  module Commands
    module Runner
      extend self

      def run(command, path = nil, arguments = nil, interpolation_values = {}, local_options = {})
        if Paperclip.logging? && (Paperclip.options[:log_command] || local_options[:log_command])
          local_options = local_options.merge(logger: Paperclip.logger)
        end

        binary = resolve_binary(command, path)

        Terrapin::CommandLine.new(binary, arguments, local_options)
                             .run(interpolation_values)
      end

      private

      def resolve_binary(command, path)
        # @deprecated +Paperclip.options[:command_path]+ will be removed in Paperclip 8.0
        path ||= Paperclip.options[:command_path]
        return command unless path

        # command may be multi-word (e.g. "magick identify")
        words = command.split(" ", 2)
        candidate = File.join(path, words[0])
        if File.executable?(candidate)
          words[0] = candidate
          words.join(" ")
        else
          command
        end
      end
    end
  end
end
