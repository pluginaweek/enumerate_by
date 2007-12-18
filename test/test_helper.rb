# Load local repository plugin paths
$:.unshift("#{File.dirname(__FILE__)}/../../../../third_party/has_finder/lib")

# Load the plugin testing framework
$:.unshift("#{File.dirname(__FILE__)}/../../../../test/plugin_test_helper/lib")
require 'rubygems'
require 'plugin_test_helper'

# Run the migrations
ActiveRecord::Migrator.migrate("#{RAILS_ROOT}/db/migrate")

# Mixin the factory helper
require File.expand_path(File.dirname(__FILE__) + '/factory')
class Test::Unit::TestCase #:nodoc:
  include Factory
end
