require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "cucumber/rake/task"

desc "Default: run unit tests."
task default: [:clean, :all]

desc "Test the paperclip plugin under all supported Rails versions."
task all: :environment do |_t|
  exec("rake spec && cucumber")
end

desc "Test the paperclip plugin."
RSpec::Core::RakeTask.new(:spec)

desc "Run integration test"
Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = %w{--format progress}
end

desc "Start an IRB session with all necessary files required."
task shell: :environment do |_t|
  chdir File.dirname(__FILE__)
  exec "irb -I lib/ -I lib/paperclip -r rubygems -r active_record -r tempfile -r init"
end

desc "Clean up files."
task clean: :environment do |_t|
  FileUtils.rm_rf "doc"
  FileUtils.rm_rf "tmp"
  FileUtils.rm_rf "pkg"
  FileUtils.rm_rf "public"
  begin
    FileUtils.rm "test/debug.log"
  rescue StandardError
    nil
  end
  begin
    FileUtils.rm "test/paperclip.db"
  rescue StandardError
    nil
  end
  Dir.glob("paperclip-*.gem").each { |f| FileUtils.rm f }
end
