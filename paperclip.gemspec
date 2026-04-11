$LOAD_PATH.push File.expand_path("lib", __dir__)
require "paperclip/version"

Gem::Specification.new do |s|
  s.name        = "kt-paperclip"
  s.version     = Paperclip::VERSION
  s.platform    = Gem::Platform::RUBY
  s.author      = "Surendra Singhi"
  s.email       = ["ssinghi@kreeti.com"]
  s.homepage    = "https://github.com/kreeti/kt-paperclip"
  s.summary     = "File attachments as attributes for ActiveRecord"
  s.description = "Easy upload management for ActiveRecord"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "shoulda_macros/**/*", "LICENSE", "README.md", "UPGRADING"]
  s.require_paths = ["lib"]

  s.requirements << "ImageMagick"
  s.required_ruby_version = ">= 2.7.0"

  s.add_dependency("activemodel", ">= 4.2.0")
  s.add_dependency("activesupport", ">= 4.2.0")
  s.add_dependency("marcel", ">= 1.0.1")
  s.add_dependency("mime-types")
  s.add_dependency("terrapin", ">= 0.6.0")
end
