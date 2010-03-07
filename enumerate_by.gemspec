# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{enumerate_by}
  s.version = "0.4.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aaron Pfeifer"]
  s.date = %q{2010-03-07}
  s.description = %q{Adds support for declaring an ActiveRecord class as an enumeration}
  s.email = %q{aaron@pluginaweek.org}
  s.files = ["lib/enumerate_by", "lib/enumerate_by/extensions", "lib/enumerate_by/extensions/associations.rb", "lib/enumerate_by/extensions/serializer.rb", "lib/enumerate_by/extensions/xml_serializer.rb", "lib/enumerate_by/extensions/base_conditions.rb", "lib/enumerate_by.rb", "test/unit", "test/unit/serializer_test.rb", "test/unit/base_conditions_test.rb", "test/unit/xml_serializer_test.rb", "test/unit/enumerate_by_test.rb", "test/unit/json_serializer_test.rb", "test/unit/associations_test.rb", "test/app_root", "test/app_root/vendor", "test/app_root/vendor/plugins", "test/app_root/vendor/plugins/plugin_with_model", "test/app_root/vendor/plugins/plugin_with_model/init.rb", "test/app_root/vendor/plugins/plugin_with_model/lib", "test/app_root/vendor/plugins/plugin_with_model/lib/plugin_with_model.rb", "test/app_root/db", "test/app_root/db/migrate", "test/app_root/db/migrate/005_create_legacy_colors.rb", "test/app_root/db/migrate/001_create_colors.rb", "test/app_root/db/migrate/006_create_tags.rb", "test/app_root/db/migrate/003_create_car_parts.rb", "test/app_root/db/migrate/004_create_orders.rb", "test/app_root/db/migrate/002_create_cars.rb", "test/app_root/app", "test/app_root/app/models", "test/app_root/app/models/car.rb", "test/app_root/app/models/color.rb", "test/app_root/app/models/legacy_color.rb", "test/app_root/app/models/car_part.rb", "test/app_root/app/models/order.rb", "test/app_root/config", "test/app_root/config/environment.rb", "test/test_helper.rb", "test/factory.rb", "CHANGELOG.rdoc", "init.rb", "LICENSE", "Rakefile", "README.rdoc"]
  s.homepage = %q{http://www.pluginaweek.org}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{pluginaweek}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Adds support for declaring an ActiveRecord class as an enumeration}
  s.test_files = ["test/unit/serializer_test.rb", "test/unit/base_conditions_test.rb", "test/unit/xml_serializer_test.rb", "test/unit/enumerate_by_test.rb", "test/unit/json_serializer_test.rb", "test/unit/associations_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
