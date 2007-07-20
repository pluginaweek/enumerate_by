require File.dirname(__FILE__) + '/../test_helper'

class AssociationsTest < Test::Unit::TestCase
  fixtures :colors, :cars
  
  def test_should_return_association
    assert_equal colors(:red), cars(:ford_mustang).color
  end
  
  def test_should_cache_association
    assert_same Color[:red], cars(:ford_mustang).color
    assert_same Color[:silver], cars(:nissan_altima_coupe).color
  end
  
  def test_should_infer_enumeration_from_association_value
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
  
  def test_should_raise_exception_on_invalid_value
    assert_raise(ActiveRecord::RecordNotFound) {cars(:ford_mustang).color = :white}
  end
end
