# frozen_string_literal: true

source "https://rubygems.org"

gemspec

rails_version = "~> #{ENV['RAILS_VERSION']}.0" if ENV["RAILS_VERSION"]
gem "rails", rails_version

# ActiveSupport's JSON encoder calls JSON.generate(jsonified, quirks_mode: true,
# max_nesting: false). json 3.0 removed the quirks_mode keyword, so to_json
# raises ArgumentError on the Rails versions that still pass it. Upstream fixed
# this in activesupport 7.2.4 and 8.1.0; it is still present in 5.2-7.1 and 8.0,
# which is why the affected list below is not a contiguous range.
json_incompatible_rails = %w[5.2 6.1 7.0 7.1 8.0]
gem "json", "< 3" if json_incompatible_rails.include?(ENV["RAILS_VERSION"])

if RUBY_ENGINE == "jruby"
  gem "activerecord-jdbcsqlite3-adapter", ">= 70.0"
else
  gem "sqlite3", ("~> 1.4" if ENV["RAILS_VERSION"]&.<("7.2"))
end

group :development, :test do
  gem "activerecord-import"
  gem "aruba"
  gem "aws-sdk-s3"
  gem "builder"
  gem "capybara"
  gem "cucumber-expressions"
  gem "cucumber-rails"
  gem "fakeweb"
  gem "fog-aws"
  gem "fog-local"
  gem "generator_spec"
  gem "launchy"
  gem "nokogiri"
  gem "ostruct" # required for Ruby >= 4.0
  gem "rake"
  gem "rspec"
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "shoulda"
  gem "timecop" unless RUBY_ENGINE == "jruby" # timecop's Time.new patch is broken on JRuby 10
end
