source "https://rubygems.org"

gemspec

rails_version = "~> #{ENV['RAILS_VERSION']}.0" if ENV["RAILS_VERSION"]
gem "rails", rails_version

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
  gem "rubocop-rails", require: false
  gem "shoulda"
  gem "timecop" unless RUBY_ENGINE == "jruby" # timecop's Time.new patch is broken on JRuby 10
end
