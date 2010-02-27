require 'config/boot'

Rails::Initializer.run do |config|
  config.plugins = %w(plugin_with_model enumerate_by)
  config.cache_classes = false
  config.whiny_nils = true
  config.action_controller.session = {:key => 'rails_session', :secret => 'd229e4d22437432705ab3985d4d246'}
end
