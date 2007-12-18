require File.dirname(__FILE__) + '/../test_helper'

class CarWithColorTest < Test::Unit::TestCase
  def setup
    @red = create_color(:id => 1, :name => 'red')
    @blue = create_color(:id => 2, :name => 'blue')
    @car = create_car(:name => 'Ford Mustang', :color_id => 1)
  end
  
  def test_should_find_association_from_id
    assert_equal @red, @car.color
  end
  
  def test_should_use_the_cached_association
    assert_same @red, @car.color
  end
  
  def test_should_infer_enumeration_from_a_symbolized_name
    @car.color = :blue
    assert_equal @blue, @car.color
  end
  
  def test_should_infer_enumeration_from_a_stringified_name
    @car.color = 'blue'
    assert_equal @blue, @car.color
  end
  
  def test_should_infer_enumeration_from_an_id
    @car.color = 2
    assert_equal @blue, @car.color
  end
  
  def test_should_infer_enumeration_from_a_record
    @car.color = @blue
    assert_equal @blue, @car.color
  end
  
  def test_should_use_nil_if_enumeration_does_not_exist
    @car.color = :green
    assert_nil @car.color
  end
  
  def teardown
    Color.destroy_all
    Car.destroy_all
  end
end

class CarAsAClassTest < Test::Unit::TestCase
  def setup
    @red = create_color(:id => 1, :name => 'red')
    @blue = create_color(:id => 2, :name => 'blue')
    @red_car = create_car(:name => 'Ford Mustang', :color_id => 1)
    @blue_car = create_car(:name => 'Ford Mustang', :color_id => 2)
  end
  
  def test_should_not_be_an_enumeration
    assert !Car.enumeration?
  end
  
  def test_should_replace_enumerations_in_dynamic_finders
    assert_equal @red_car, Car.find_by_color(:red)
  end
  
  def test_should_replace_enumerations_in_find_conditions
    assert_equal @red_car, Car.find(:first, :conditions => {:color => :red})
  end
  
  def test_should_still_be_able_to_find_with_an_id
    assert_equal @red_car, Car.find_by_color_id(@red.id)
  end
  
  def test_should_have_a_finder_association_for_each_enumeration_identifier
    assert_equal [@red_car], Car.red.find(:all)
    assert_equal [@blue_car], Car.blue.find(:all)
  end
  
  def teardown
    Color.destroy_all
    Car.destroy_all
  end
end
