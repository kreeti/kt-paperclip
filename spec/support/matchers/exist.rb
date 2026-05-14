# frozen_string_literal: true

RSpec::Matchers.define :exist do |_expected|
  match do |actual|
    File.exist?(actual)
  end
end
