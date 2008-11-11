require File.dirname(__FILE__) + '/../test_helper'

class CollectionTest < Test::Unit::TestCase
  def setup
    red = create_color(:id => 1, :name => 'red')
    blue = create_color(:id => 2, :name => 'green')
    @collection = PluginAWeek::ActsAsEnumeration::Collection.new([red, blue])
  end
  
  def test_should_be_able_to_convert_to_json
    assert_equal '[{"name": "red", "id": 1}, {"name": "green", "id": 2}]', @collection.to_json
  end
  
  def teardown
    Color.destroy_all
  end
end
