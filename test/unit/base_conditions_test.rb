require File.dirname(__FILE__) + '/../test_helper'

class AssociationsTest < Test::Unit::TestCase
  fixtures :colors, :cars
  
  def test_should_replace_enumerations_in_dynamic_finders
    assert_equal cars(:ford_mustang), Car.find_by_color(:red)
  end
  
  def test_should_replace_enumerations_in_find_conditions
    assert_equal cars(:ford_mustang), Car.find(:first, :conditions => {:color => :red})
  end
  
  def test_should_still_be_able_to_find_with_id
    assert_equal cars(:ford_mustang), Car.find_by_color_id(colors(:red).id)
  end
end