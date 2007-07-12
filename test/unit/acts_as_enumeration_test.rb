require File.dirname(__FILE__) + '/../test_helper'

class ActsAsEnumerationTest < Test::Unit::TestCase
  fixtures :colors, :cars
  
  def test_valid_enumeration
    assert Color.new(:name => 'white').valid?
  end
  
  def test_invalid_enumeration
    assert !Color.new(:name => 'black').valid?
  end
  
  def test_all_finds_all_values
    assert_equal 5, Color.all.size
  end
  
  def test_all_values_frozen
    assert Color.all.frozen?
    Color.all.each {|color| assert color.frozen?}
  end
  
  def test_find_by_id_valid
    assert_equal colors(:red), Color.find_by_id(1)
  end
  
  def test_find_by_id_invalid
    assert_nil Color.find_by_id(-1)
  end
  
  def test_find_by_name_valid
    assert_equal colors(:red), Color.find_by_name(:red)
    assert_equal colors(:red), Color.find_by_name('red')
  end
  
  def test_find_by_name_invalid
    assert_nil Color.find_by_name(:white)
    assert_nil Color.find_by_name('white')
  end
  
  def test_value_included_in_enumeration
    assert Color.includes?(:red)
    assert Color.includes?('red')
    assert Color.includes?(1)
  end
  
  def test_value_not_included_in_enumeration
    assert !Color.includes?(:white)
    assert !Color.includes?('white')
    assert !Color.includes?(-1)
  end
  
  def test_find_enumeration_with_unknown_type
    assert_equal colors(:red), Color[:red]
    assert_equal colors(:red), Color['red']
    assert_equal colors(:red), Color[1]
  end
  
  def test_find_enumeration_with_invalid_id
    assert_raise(ActiveRecord::RecordNotFound) {Color[:white]}
    assert_raise(ActiveRecord::RecordNotFound) {Color['white']}
    assert_raise(ActiveRecord::RecordNotFound) {Color[-1]}
  end
  
  def test_find_enumeration_with_invalid_type
    assert_raise(TypeError) {Color[Car.new]}
  end
  
  def test_all_is_cached
    assert_same Color.all, Color.all
  end
  
  def test_find_by_id_is_cached
    assert_same Color.find_by_id(1), Color.find_by_id(1)
  end
  
  def test_find_by_name_is_cached
    assert_same Color.find_by_name(:red), Color.find_by_name(:red)
  end
  
  def test_reset_cache
    all_colors = Color.all
    red = Color.find_by_id(1)
    blue = Color.find_by_name(:blue)
    
    Color.reset_cache
    
    assert_not_same all_colors, Color.all
    assert_not_same red, Color.find_by_id(1)
    assert_not_same blue, Color.find_by_name(:blue)
  end
  
  def test_to_sym
    red = colors(:red)
    assert_equal 'red', red.name
    assert_equal :red, red.to_sym
  end
  
  def test_equality
    red = colors(:red)
    assert red === :red
    assert red === 1
    assert red === 'red'
  end
  
  def test_in
    assert colors(:red).in?('red')
    assert !colors(:red).in?('blue', :green)
  end
  
  def teardown
    Color.reset_cache
  end
end
