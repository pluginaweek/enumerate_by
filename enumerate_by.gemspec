$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'enumerate_by/version'

Gem::Specification.new do |s|
  s.name              = "enumerate_by"
  s.version           = EnumerateBy::VERSION
  s.authors           = ["Aaron Pfeifer"]
  s.email             = "aaron@pluginaweek.org"
  s.homepage          = "http://www.pluginaweek.org"
  s.description       = "Adds support for declaring an ActiveRecord class as an enumeration"
  s.summary           = "Enumerations in ActiveRecord"
  s.require_paths     = ["lib"]
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- test/*`.split("\n")
  s.rdoc_options      = %w(--line-numbers --inline-source --title enumerate_by --main README.rdoc)
  s.extra_rdoc_files  = %w(README.rdoc CHANGELOG.rdoc LICENSE)
  
  s.add_development_dependency("rake")
  s.add_development_dependency("plugin_test_helper", ">= 0.3.2")
end
