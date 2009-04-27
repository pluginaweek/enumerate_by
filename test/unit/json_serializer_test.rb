require File.dirname(__FILE__) + '/../test_helper'

class JSONSerializerTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => @red)
    @json = @car.to_json
  end
  
  def test_should_include_enumeration_in_json
    assert_match %r{"color": "red"}, @json
  end
  
  def test_should_render_other_attributes
    assert_match %r{"id": #{@car.id}}, @json
    assert_match %r{"name": "Ford Mustang"}, @json
  end
end
