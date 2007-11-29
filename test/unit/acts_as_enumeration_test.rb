require File.dirname(__FILE__) + '/../test_helper'

class ActsAsEnumerationTest < Test::Unit::TestCase
  fixtures :colors, :cars
  
  def test_should_require_unique_name
    assert Color.new(:name => 'white').valid?
    assert !Color.new(:name => 'black').valid?
  end
  
  def test_should_be_enumeration_if_acts_as_enumeration
    assert Color.enumeration?
  end
  
  def test_should_not_be_enumeration_if_does_not_act_as_enumeration
    assert !Size.enumeration?
  end
  
  def test_all_should_find_all_models
    assert_equal 5, Color.all.size
    assert (Color.find(:all) - Color.all).empty?
  end
  
  def test_all_should_freeze_values
    assert Color.all.frozen?
    
    Color.all.each do |color|
      assert color.frozen?
    end
  end
  
  def test_should_find_model_for_valid_id
    assert_equal colors(:red), Color.find_by_id(1)
  end
  
  def test_should_not_find_model_for_invalid_id
    assert_nil Color.find_by_id(-1)
  end
  
  def test_should_find_model_for_valid_name_as_symbol
    assert_equal colors(:red), Color.find_by_name(:red)
  end
  
  def test_should_find_model_for_valid_name_as_string
    assert_equal colors(:red), Color.find_by_name('red')
  end
  
  def test_should_not_find_model_for_valid_name_as_symbol
    assert_nil Color.find_by_name(:white)
  end
  
  def test_should_not_find_model_for_valid_name_as_string
    assert_nil Color.find_by_name('white')
  end
  
  def test_valid_symbol_should_be_included_in_enumeration
    assert Color.includes?(:red)
  end
  
  def test_valid_string_should_be_included_in_enumeration
    assert Color.includes?('red')
  end
  
  def test_valid_id_should_be_included_in_enumeration
    assert Color.includes?(1)
  end
  
  def test_invalid_symbol_should_not_be_included_in_enumeration
    assert !Color.includes?(:white)
  end
  
  def test_invalid_string_should_not_be_included_in_enumeration
    assert !Color.includes?('white')
  end
  
  def test_invalid_id_should_not_be_included_in_enumeration
    assert !Color.includes?(-1)
  end
  
  def test_should_find_indexed_model_for_valid_symbol
    assert_equal colors(:red), Color[:red]
  end
  
  def test_should_find_indexed_model_for_valid_string
    assert_equal colors(:red), Color['red']
  end
  
  def test_should_find_indexed_model_for_valid_id
    assert_equal colors(:red), Color[1]
  end
  
  def test_should_raise_exception_for_invalid_indexed_symbol
    assert_raise(ActiveRecord::RecordNotFound) {Color[:white]}
  end
  
  def test_should_raise_exception_for_invalid_indexed_string
    assert_raise(ActiveRecord::RecordNotFound) {Color['white']}
  end
  
  def test_should_raise_exception_for_invalid_indexed_id
    assert_raise(ActiveRecord::RecordNotFound) {Color[-1]}
  end
  
  def test_should_raise_exception_for_invalid_indexed_type
    assert_raise(TypeError) {Color[Car.new]}
  end
  
  def test_should_cache_all
    assert_same Color.all, Color.all
  end
  
  def test_find_by_id_should_cache_models
    assert_same Color.find_by_id(1), Color.find_by_id(1)
  end
  
  def test_find_by_name_should_cache_models
    assert_same Color.find_by_name(:red), Color.find_by_name(:red)
  end
  
  def test_should_clear_all_cache_on_reset_cache
    all_colors = Color.all
    Color.reset_cache
    assert_not_same all_colors, Color.all
  end
  
  def test_should_clear_id_cache_on_reset_cache
    red = Color.find_by_id(1)
    Color.reset_cache
    assert_not_same red, Color.find_by_id(1)
  end
  
  def test_should_clear_name_cache_on_reset_cache
    blue = Color.find_by_name(:blue)
    Color.reset_cache
    assert_not_same blue, Color.find_by_name(:blue)
  end
  
  def test_should_clear_cache_after_model_is_created
    all_colors = Color.all
    Color.create(:name => 'white')
    assert_not_same all_colors, Color.all
    assert_equal all_colors.size + 1, Color.all.size
  end
  
  def test_should_clear_cache_after_model_is_saved
    all_colors = Color.all
    color = colors(:red)
    color.name = 'white'
    color.save
    assert_not_same all_colors, Color.all
  end
  
  def test_to_sym_should_return_symbolized_name
    assert_equal :red, colors(:red).to_sym
  end
  
  def test_to_s_should_return_stringified_name
    assert_equal 'red', colors(:red).to_s
  end
  
  def test_should_respond_to_identifier_queries
    assert colors(:red).red?
    assert !colors(:red).blue?
    assert !colors(:red).green?
  end
  
  def test_should_handle_case_equality_for_symbolized_name
    assert colors(:red) === :red
  end
  
  def test_should_handle_case_equality_for_stringified_name
    assert colors(:red) === 'red'
  end
  
  def test_should_handle_case_equality_for_id
    assert colors(:red) === 1
  end
  
  def test_enumerated_value_should_be_in_valid_value
    assert colors(:red).in?('red')
  end
  
  def test_enumerated_value_should_not_be_in_invalid_values
    assert !colors(:red).in?('blue', :green)
  end
  
  def teardown
    Color.reset_cache
  end
end
