# frozen_string_literal: true

module Paperclip
  module Helpers
    def configure
      yield(self) if block_given?
    end

    def interpolates(key, &block)
      Paperclip::Interpolations[key] = block
    end

    # @deprecated Will be removed in Paperclip 8.0. Use +Paperclip::Commands::Runner.run+ instead.
    def run(command, arguments = nil, interpolation_values = {}, local_options = {})
      Commands::Runner.run(command, nil, arguments, interpolation_values, local_options)
    end

    # Find all instances of the given Active Record model +klass+ with attachment +name+.
    # This method is used by the refresh rake tasks.
    def each_instance_with_attachment(klass, name)
      class_for(klass).unscoped.where("#{name}_file_name IS NOT NULL").find_each do |instance|
        yield(instance)
      end
    end

    def class_for(class_name)
      class_name.split("::").inject(Object) do |klass, partial_class_name|
        if klass.const_defined?(partial_class_name)
          klass.const_get(partial_class_name, false)
        else
          klass.const_missing(partial_class_name)
        end
      end
    end

    def reset_duplicate_clash_check!
      @names_url = nil
    end
  end
end
