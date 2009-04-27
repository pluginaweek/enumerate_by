require File.dirname(__FILE__) + '/../test_helper'

class EnumerationWithFinderConditionsTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @blue = create_color(:name => 'blue')
    @red_car = create_car(:name => 'Ford Mustang', :color => @red)
    @blue_car = create_car(:name => 'Ford Mustang', :color => @blue)
  end
  
  def test_should_replace_enumerations_in_dynamic_finders
    assert_equal @red_car, Car.find_by_color('red')
  end
  
  def test_should_replace_multiple_enumerations_in_dynamic_finders
    assert_equal [@red_car, @blue_car], Car.find_all_by_color(%w(red blue))
  end
  
  def test_should_replace_enumerations_in_find_conditions
    assert_equal @red_car, Car.first(:conditions => {:color => 'red'})
  end
  
  def test_should_replace_multiple_enumerations_in_find_conditions
    assert_equal [@red_car, @blue_car], Car.all(:conditions => {:color => %w(red blue)})
  end
end

class EnumerationWithFinderUpdatesTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @blue = create_color(:name => 'blue')
    @red_car = create_car(:name => 'Ford Mustang', :color => @red)
  end
  
  def test_should_replace_enumerations_in_update_conditions
    Car.update_all({:color => 'blue'}, :name => 'Ford Mustang')
    @red_car.reload
    assert_equal @blue, @red_car.color
  end
  
  def test_should_not_replace_multiple_enumerations_in_update_conditions
    Car.update_all({:color => %w(red blue)}, :name => 'Ford Mustang')
    @red_car.reload
    assert_equal @red, @red_car.color
  end
end
