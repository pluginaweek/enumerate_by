require File.dirname(__FILE__) + '/../test_helper'

class JSONSerializerTest < Test::Unit::TestCase
  def setup
    @color = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => 'red')
  end
  
  def test_should_be_able_to_convert_to_xml
    json = @car.to_json
    
    assert_match %r{"color": "red"}, json
    assert_match %r{"id": #{@car.id}}, json
    assert_match %r{"manufacturer": null}, json
    assert_match %r{"name": "Ford Mustang"}, json
  end
  
  def teardown
    Color.destroy_all
  end
end
