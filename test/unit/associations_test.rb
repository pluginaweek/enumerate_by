require File.dirname(__FILE__) + '/../test_helper'

class AssociationsTest < Test::Unit::TestCase
  fixtures :colors, :cars
  
  def test_association
    assert_equal colors(:red), cars(:ford_mustang).color
  end
  
  def test_association_is_cached
    assert_same Color[:red], cars(:ford_mustang).color
    assert_same Color[:silver], cars(:nissan_altima_coupe).color
  end
  
  def test_association_new_value
    car = cars(:ford_mustang)
    car.color = :silver
    assert_equal colors(:silver), car.color
    
    car.color = 'silver'
    assert_equal colors(:silver), car.color
    
    car.color = 2
    assert_equal colors(:silver), car.color
    
    car.color = colors(:silver)
    assert_equal colors(:silver), car.color
  end
  
  def test_association_with_new_invalid_value
    assert_raise(ActiveRecord::RecordNotFound) {cars(:ford_mustang).color = :white}
  end
end
