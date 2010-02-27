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
  
  def test_should_raise_exception_for_invalid_enumeration_in_dynamic_finders
    assert_raise(ActiveRecord::RecordNotFound) { Car.find_by_color('invalid') }
  end
  
  def test_should_still_allow_non_enumeration_in_dynamic_finders
    assert_equal @red_car, Car.find_by_id(@red_car.id)
  end
  
  def test_should_replace_multiple_enumerations_in_dynamic_finders
    assert_equal [@red_car, @blue_car], Car.find_all_by_color(%w(red blue))
  end
  
  def test_should_raise_exception_for_any_invalid_enumeration_in_dynamic_finders
    assert_raise(ActiveRecord::RecordNotFound) { Car.find_all_by_color(%w(red invalid)) }
  end
  
  def test_should_still_allow_multiple_non_enumerations_in_dynamic_finders
    assert_equal [@red_car, @blue_car], Car.find_all_by_id([@red_car.id, @blue_car.id])
  end
  
  def test_should_replace_enumerations_in_find_conditions
    assert_equal @red_car, Car.first(:conditions => {:color => 'red'})
  end
  
  def test_should_raise_exception_for_invalid_enumeration_in_find_conditions
    assert_raise(ActiveRecord::RecordNotFound) { Car.first(:conditions => {:color => 'invalid'}) }
  end
  
  def test_should_still_allow_non_enumeration_in_find_conditions
    assert_equal @red_car, Car.first(:conditions => {:id => @red_car.id})
  end
  
  def test_should_replace_multiple_enumerations_in_find_conditions
    assert_equal [@red_car, @blue_car], Car.all(:conditions => {:color => %w(red blue)})
  end
  
  def test_should_raise_exception_for_any_invalid_enumeration_in_find_conditions
    assert_raise(ActiveRecord::RecordNotFound) { Car.all(:conditions => {:color => %w(red invalid)}) }
  end
  
  def test_should_still_allow_multiple_non_enumerations_in_find_conditions
    assert_equal [@red_car, @blue_car], Car.all(:conditions => {:id => [@red_car.id, @blue_car.id]})
  end
end

class EnumerationWithCustomPrimaryKeyAndFinderConditionsTest < ActiveRecord::TestCase
  def setup
    @red = create_legacy_color(:name => 'red')
    @blue = create_legacy_color(:name => 'blue')
    @red_car = create_car(:name => 'Ford Mustang', :legacy_color => @red)
    @blue_car = create_car(:name => 'Ford Mustang', :legacy_color => @blue)
  end
  
  def test_should_replace_enumerations_in_dynamic_finders
    assert_equal @red_car, Car.find_by_legacy_color('red')
  end
  
  def test_should_replace_enumerations_in_find_conditions
    assert_equal @red_car, Car.first(:conditions => {:legacy_color => 'red'})
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
  
  def test_should_raise_exception_for_invalid_enumeration_in_update_conditions
    assert_raise(ActiveRecord::RecordNotFound) { Car.update_all({:color => 'invalid'}, :name => 'Ford Mustang') }
  end
  
  def test_should_still_allow_non_enumeration_in_update_conditions
    Car.update_all({:color => 'blue'}, :id => @red_car.id)
    @red_car.reload
    assert_equal @blue, @red_car.color
  end
  
  def test_should_not_replace_multiple_enumerations_in_update_conditions
    Car.update_all({:color => %w(red blue)}, :name => 'Ford Mustang')
    @red_car.reload
    assert_equal @red, @red_car.color
  end
end

class EnumerationWithCustomPrimaryKeyAndFinderUpdatesTest < ActiveRecord::TestCase
  def setup
    @red = create_legacy_color(:name => 'red')
    @blue = create_legacy_color(:name => 'blue')
    @red_car = create_car(:name => 'Ford Mustang', :legacy_color => @red)
  end
  
  def test_should_replace_enumerations_in_update_conditions
    Car.update_all({:legacy_color => 'blue'}, :name => 'Ford Mustang')
    @red_car.reload
    assert_equal @blue, @red_car.legacy_color
  end
end
