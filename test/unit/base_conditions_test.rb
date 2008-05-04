require File.dirname(__FILE__) + '/../test_helper'

class EnumerationWithFinderConditionsTest < Test::Unit::TestCase
  def setup
    @red = create_color(:id => 1, :name => 'red')
    @blue = create_color(:id => 2, :name => 'blue')
    @red_car = create_car(:name => 'Ford Mustang', :color_id => 1)
  end
  
  def test_should_replace_enumerations_in_dynamic_finders
    assert_equal @red_car, Car.find_by_color(:red)
  end
  
  def test_should_replace_enumerations_in_find_conditions
    assert_equal @red_car, Car.find(:first, :conditions => {:color => :red})
  end
  
  def teardown
    Color.destroy_all
    Car.destroy_all
  end
end
