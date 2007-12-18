require File.dirname(__FILE__) + '/../test_helper'

class ColorByDefaultTest < Test::Unit::TestCase
  def setup
    @color = Color.new
  end
  
  def test_should_not_have_a_name
    assert @color.name.blank?
  end
end

class ColorTest < Test::Unit::TestCase
  def test_should_be_an_enumeration
    assert Color.enumeration?
  end
  
  def test_should_have_two_columns
    assert_equal 2, Color.columns.size
  end
  
  def test_should_require_a_name
    color = new_color(:name => nil)
    assert !color.valid?
    assert_equal 1, color.errors.on(:name).to_a.length
  end
  
  def test_should_require_a_unique_name
    color = new_color(:name => 'red')
    color.save!
    
    color = new_color(:name => 'red')
    assert !color.valid?
    assert_equal 1, color.errors.on(:name).to_a.length
  end
  
  def teardown
    Color.destroy_all
  end
end

class ColorWithNoExistingRecordsTest < Test::Unit::TestCase
  def test_should_not_have_any_records
    assert_equal [], Color.find(:all)
  end
end

class ColorWithExistingRecordsTest < Test::Unit::TestCase
  def setup
    @red = create_color(:id => 1, :name => 'red')
    @green = create_color(:id => 2, :name => 'green')
    @blue = create_color(:id => 3, :name => 'blue')
  end
  
  def test_should_be_able_to_find_all_records
    assert_equal [@red, @green, @blue], Color.find(:all)
  end
  
  def test_result_should_be_frozen_when_finding_all_records
    assert Color.find(:all).frozen?
  end
  
  def test_should_allow_finding_with_id
    assert_equal @red, Color.find(1)
  end
  
  def test_should_raise_exception_if_finding_with_invalid_id
    assert_raise(ActiveRecord::RecordNotFound) {Color.find(-1)}
  end
  
  def test_should_allow_finding_with_multiple_ids
    assert_equal [@red, @green], Color.find(1, 2)
  end
  
  def test_should_raise_exception_if_finding_with_multiple_invalid_ids
    assert_raise(ActiveRecord::RecordNotFound) {Color.find(1, -1)}
  end
  
  def test_should_ignore_finder_options
    assert_equal @red, Color.find(1, :limit => 10, :conditions => {:name => 'blue'})
  end
  
  def test_should_be_able_to_find_by_id
    assert_equal @red, Color.find_by_id(1)
  end
  
  def test_should_find_nothing_if_finding_by_invalid_id
    assert_nil Color.find_by_id(-1)
  end
  
  def test_should_allow_finding_by_name_with_a_symbol
    assert_equal @red, Color.find_by_name(:red)
  end
  
  def test_should_allow_finding_by_name_with_a_string
    assert_equal @red, Color.find_by_name('red')
  end
  
  def test_should_find_nothing_if_finding_by_invalid_name_with_a_symbol
    assert_nil Color.find_by_name(:invalid)
  end
  
  def test_should_find_nothing_if_finding_by_invalid_name_with_a_string
    assert_nil Color.find_by_name('invalid')
  end
  
  def test_valid_symbol_should_be_included
    assert Color.includes?(:red)
  end
  
  def test_valid_string_should_be_included
    assert Color.includes?('red')
  end
  
  def test_valid_id_should_be_included
    assert Color.includes?(1)
  end
  
  def test_invalid_symbol_should_not_be_included
    assert !Color.includes?(:white)
  end
  
  def test_invalid_string_should_not_be_included
    assert !Color.includes?('white')
  end
  
  def test_invalid_id_should_not_be_included
    assert !Color.includes?(-1)
  end
  
  def test_should_find_indexed_model_with_a_symbol
    assert_equal @red, Color[:red]
  end
  
  def test_should_find_indexed_model_with_a_string
    assert_equal @red, Color['red']
  end
  
  def test_should_find_indexed_model_with_an_id
    assert_equal @red, Color[1]
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
    assert_raise(TypeError) {Color[Object.new]}
  end
  
  def test_should_allow_finding_by_any_with_symbol
    assert_equal @red, Color.find_by_any(:red)
  end
  
  def test_should_allow_finding_by_any_with_string
    assert_equal @red, Color.find_by_any('red')
  end
  
  def test_should_allow_finding_by_any_with_id
    assert_equal @red, Color.find_by_any(1)
  end
  
  def test_should_allow_finding_by_any_with_nil
    assert_nil Color.find_by_any(nil)
  end
  
  def test_should_find_nothing_if_finding_by_any_with_invalid_symbol
    assert_nil Color.find_by_any(:invalid)
  end
  
  def test_should_find_nothing_if_finding_by_any_with_invalid_string
    assert_nil Color.find_by_any('invalid')
  end
  
  def test_should_find_nothing_if_finding_by_any_with_invalid_id
    assert_nil Color.find_by_any(-1)
  end
  
  def test_should_raise_exception_if_finding_by_any_with_invalid_type
    assert_raise(TypeError) {Color.find_by_any(Object.new)}
  end
  
  def test_should_allow_counting
    assert_equal 3, Color.count
  end
  
  def teardown
    Color.destroy_all
  end
end

class ColorWithCacheTest < Test::Unit::TestCase
  def setup
    @red = create_color(:id => 1, :name => 'red')
    @green = create_color(:id => 2, :name => 'green')
  end
  
  def test_should_cache_all_records
    assert_same Color.find(:all), Color.find(:all)
  end
  
  def test_should_cache_records_found_by_id
    assert_same Color.find_by_id(1), Color.find_by_id(1)
  end
  
  def test_should_cache_records_found_by_name
    assert_same Color.find_by_name(:red), Color.find_by_name(:red)
  end
  
  def test_should_clear_all_cache_after_resetting_the_cache
    all_colors = Color.find(:all)
    Color.reset_cache
    assert_not_same all_colors, Color.find(:all)
  end
  
  def test_should_clear_id_cache_after_resetting_the_cache
    red = Color.find_by_id(1)
    red.id = 4
    Color.reset_cache
    assert_same red, Color.find_by_id(4)
  end
  
  def test_should_clear_name_cache_after_resetting_the_cache
    green = Color.find_by_name(:green)
    green.name = 'blue'
    Color.reset_cache
    assert_same green, Color.find_by_name(:blue)
  end
  
  def test_should_clear_cache_after_creating_a_new_record
    all_colors = Color.find(:all)
    create_color(:id => 3, :name => 'blue')
    assert_not_same all_colors, Color.find(:all)
    assert_equal all_colors.size + 1, Color.find(:all).size
  end
  
  def test_should_clear_cache_after_destroying_an_existing_record
    all_colors = Color.find(:all)
    @green.destroy
    assert_not_same all_colors, Color.find(:all)
    assert_equal all_colors.size - 1, Color.find(:all).size
  end
  
  def teardown
    Color.destroy_all
  end
end

class ColorAfterBeingCreatedTest < Test::Unit::TestCase
  def setup
    @red = create_color(:id => 1, :name => 'red')
    @green = create_color(:id => 2, :name => 'green')
    @blue = create_color(:id => 3, :name => 'blue')
  end
  
  def test_should_not_be_a_new_record
    assert !@red.new_record?
  end
  
  def test_should_be_readonly
    assert @red.readonly?
  end
  
  def test_should_have_an_id
    assert_equal 1, @red.id
  end
  
  def test_should_not_be_allowed_to_be_updated
    @red.name = 'white'
    assert_raise(ActiveRecord::ReadOnlyRecord) {@red.save}
  end
  
  def test_should_be_allowed_to_be_destroy
    @red.destroy
    assert @red.frozen?
  end
  
  def test_should_use_the_identifier_name_for_symbolization
    assert_equal :red, @red.to_sym
  end
  
  def test_should_use_the_identifier_name_for_stringification
    assert_equal 'red', @red.to_s
  end
  
  def test_should_respond_to_identifier_queries
    assert @red.red?
    assert !@red.blue?
    assert !@red.green?
  end
  
  def test_should_be_allowed_to_reload
    assert @red.reload
  end
  
  def test_should_handle_case_equality_for_symbolized_name
    assert @red === :red
  end
  
  def test_should_handle_case_equality_for_stringified_name
    assert @red === 'red'
  end
  
  def test_should_handle_case_equality_for_id
    assert @red === 1
  end
  
  def test_should_be_found_in_a_list_of_valid_names
    assert @red.in?('red')
  end
  
  def test_should_not_be_found_in_a_list_of_invalid_names
    assert !@red.in?('blue', :green)
  end
  
  def teardown
    Color.destroy_all
  end
end

class ColorWithNonAlphaCharactersTest < Test::Unit::TestCase
  def setup
    @hot_red = create_color(:id => 4, :name => 'Hot-Red!')
  end
  
  def test_should_allow_finding_by_actual_name
    assert_equal @hot_red, Color.find_by_name(:'hot_red')
  end
  
  def test_should_allow_finding_by_safe_name
    assert_equal @hot_red, Color.find_by_name(:'Hot-Red!')
  end
  
  def teardown
    Color.destroy_all
  end
end
