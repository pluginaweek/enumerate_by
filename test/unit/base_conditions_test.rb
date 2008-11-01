require File.dirname(__FILE__) + '/../test_helper'

class EnumerationWithFinderConditionsTest < Test::Unit::TestCase
  def setup
    @red = create_color(:id => 1, :name => 'red')
    @blue = create_color(:id => 2, :name => 'blue')
    @red_car = create_car(:name => 'Ford Mustang', :color_id => 1)
    @blue_car = create_car(:name => 'Ford Mustang', :color_id => 2)
  end
  
  def test_should_replace_enumerations_in_dynamic_finders
    assert_equal @red_car, Car.find_by_color('red')
  end
  
  def test_should_replace_multiple_enumerations_in_dynamic_finders
    assert_equal [@red_car, @blue_car], Car.find_all_by_color(%w(red blue))
  end
  
  def test_should_replace_enumerations_in_find_conditions
    assert_equal @red_car, Car.find(:first, :conditions => {:color => 'red'})
  end
  
  def test_should_replace_multiple_enumerations_in_find_conditions
    assert_equal [@red_car, @blue_car], Car.find(:all, :conditions => {:color => %w(red blue)})
  end
  
  def teardown
    Color.destroy_all
  end
end

class EnumerationWithFinderUpdatesTest < Test::Unit::TestCase
  def setup
    @red = create_color(:id => 1, :name => 'red')
    @blue = create_color(:id => 2, :name => 'blue')
    @red_car = create_car(:name => 'Ford Mustang', :color_id => 1)
  end
  
  def test_should_replace_enumerations_in_update_conditions
    Car.update_all({:color => 'blue'}, :name => 'Ford Mustang')
    @red_car.reload
    assert_equal 'blue', @red_car.color
  end
  
  def test_should_not_replace_multiple_enumerations_in_update_conditions
    assert_raise(ActiveRecord::RecordNotFound) {Car.update_all({:color => %w(red blue)}, :name => 'Ford Mustang')}
  end
  
  def teardown
    Color.destroy_all
  end
end
