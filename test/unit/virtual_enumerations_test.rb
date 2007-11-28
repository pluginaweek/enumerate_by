require File.dirname(__FILE__) + '/../test_helper'

class VirtualEnumerationsTest < Test::Unit::TestCase
  fixtures :colors, :cars
  
  def test_should_find_all_ratings
    assert_equal %w(good bad ugly), Rating.find(:all).map(&:name)
  end
  
  def test_should_find_first_rating
    assert_equal 'good', Rating.find(:first).name
  end
  
  def test_should_find_specific_rating
    assert_equal 'bad', Rating.find(2).name
  end
  
  def test_should_find_enumeration_association
    assert_equal 'ugly', Car.find(3).rating.name
  end
end
