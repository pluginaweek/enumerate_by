require File.dirname(__FILE__) + '/../test_helper'

class EnumerationByDefaultTest < Test::Unit::TestCase
  def setup
    @color = Color.new
  end
  
  def test_should_not_have_an_id
    assert @color.id.blank?
  end
  
  def test_should_not_have_a_name
    assert @color.name.blank?
  end
  
  def test_should_be_a_new_record
    assert @color.new_record?
  end
  
  def test_should_not_have_any_attributes_protected
    assert_equal [], @color.attributes_protected_by_default
  end
end

class EnumerationTest < Test::Unit::TestCase
  def test_should_be_an_enumeration
    assert Color.enumeration?
  end
  
  def test_should_have_two_columns
    assert_equal 2, Color.columns.size
  end
  
  def test_should_require_an_id
    color = new_color(:id => nil)
    assert !color.valid?
    assert_equal 1, Array(color.errors.on(:id)).size
  end
  
  def test_should_require_a_name
    color = new_color(:name => nil)
    assert !color.valid?
    assert_equal 1, Array(color.errors.on(:name)).size
  end
  
  def test_should_require_a_unique_name
    color = create_color(:name => 'red')
    
    second_color = new_color(:name => 'red')
    assert !second_color.valid?
    assert_equal 1, Array(second_color.errors.on(:name)).size
  end
  
  def teardown
    Color.destroy_all
  end
end

class EnumerationWithNoExistingRecordsTest < Test::Unit::TestCase
  def test_should_not_have_any_records
    assert_equal [], Color.find(:all)
  end
end

class EnumerationWithExistingRecordsTest < Test::Unit::TestCase
  def setup
    @red = create_color(:id => 1, :name => 'red')
    @green = create_color(:id => 2, :name => 'green')
    @blue = create_color(:id => 3, :name => 'blue')
  end
  
  def test_should_be_able_to_find_all_records
    assert_equal [@red, @green, @blue], Color.find(:all)
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
    assert_equal @red, Color.find(:first, :conditions => {:name => 'blue'})
  end
  
  def test_should_be_able_to_find_by_id
    assert_equal @red, Color.find_by_id(1)
  end
  
  def test_should_find_nothing_if_finding_by_invalid_id
    assert_nil Color.find_by_id(-1)
  end
  
  def test_should_allow_finding_all_by_name_with_a_symbol
    assert_equal [@red], Color.find_all_by_name(:red)
  end
  
  def test_should_allow_finding_all_by_name_with_a_string
    assert_equal [@red], Color.find_all_by_name('red')
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
  
  def test_should_allow_counting
    assert_equal 3, Color.count
  end
  
  def teardown
    Color.destroy_all
  end
end

class EnumerationWithCacheTest < Test::Unit::TestCase
  def setup
    @red = create_color(:id => 1, :name => 'red')
    @green = create_color(:id => 2, :name => 'green')
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

class EnumerationAfterBeingCreatedTest < Test::Unit::TestCase
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
    assert_raise(ActiveRecord::ReadOnlyRecord) {@red.save!}
  ensure
    Color.reset_cache
  end
  
  def test_should_be_allowed_to_be_destroyed
    @red.destroy
    assert @red.frozen?
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
  
  def test_should_stringify_enumeration_attributes
    assert_equal 'red', @red.to_s
    assert_equal 'red', @red.to_str
  end
  
  def test_should_arify_enumeration_attributes
    assert_equal %w(red), @red.to_ary
  end
  
  def test_should_be_able_to_compare_with_strings
    assert 'red' == @red
    assert @red == 'red'
  end
  
  def test_should_be_able_to_compare_with_arrays
    assert %w(red) == @red.to_ary
    assert @red.to_ary == %w(red)
  end
  
  def teardown
    Color.destroy_all
  end
end

class EnumerationWithNonAlphaCharactersTest < Test::Unit::TestCase
  def setup
    @hot_red = create_color(:id => 4, :name => 'Hot-Red!')
  end
  
  def test_should_allow_finding_by_actual_name
    assert_equal @hot_red, Color.find_by_name('Hot-Red!')
  end
  
  def teardown
    Color.destroy_all
  end
end

class EnumerationWithCustomColumnsTest < Test::Unit::TestCase
  def setup
    create_country(:name => 'United States')
    @new_jersey = create_region(:id => 1, :name => 'New Jersey', :country => 'United States')
    @new_york = create_region(:id => 2, :name => 'New York', :country => 'United States')
  end
  
  def test_should_have_more_than_two_columns
    assert_equal 3, Region.columns.size
  end
  
  def test_should_allow_finding_by_all_for_custom_column
    assert_equal [@new_jersey, @new_york], Region.find_all_by_country_id(1)
  end
  
  def test_should_all_finding_by_custom_column
    assert_equal @new_jersey, Region.find_by_country_id(1)
  end
  
  def teardown
    Region.destroy_all
    Country.destroy_all
  end
end

class EnumerationWithCustomAttributesTest < Test::Unit::TestCase
  def setup
    @blink = create_book(:title => 'Blink')
  end
  
  def test_should_not_have_a_title
    book = Book.new
    assert book.title.blank?
  end
  
  def test_should_have_2_columns
    assert_equal 2, Book.columns.size
  end
  
  def test_should_require_a_title
    book = new_book(:title => nil)
    assert !book.valid?
    assert_equal 1, Array(book.errors.on(:title)).size
  end
  
  def test_should_allow_finding_all_by_title_with_symbol
    assert_equal [@blink], Book.find_all_by_title(:Blink)
  end
  
  def test_should_allow_finding_all_by_title_with_string
    assert_equal [@blink], Book.find_all_by_title('Blink')
  end
  
  def test_should_allow_finding_by_title_with_symbol
    assert_equal @blink, Book.find_by_title(:Blink)
  end
  
  def test_should_allow_finding_by_title_with_string
    assert_equal @blink, Book.find_by_title('Blink')
  end
  
  def test_should_find_indexed_model_with_a_symbol
    assert_equal @blink, Book[:Blink]
  end
  
  def test_should_find_indexed_model_with_a_string
    assert_equal @blink, Book['Blink']
  end
  
  def test_should_allow_finding_by_any_with_symbol
    assert_equal @blink, Book.find_by_any(:Blink)
  end
  
  def test_should_allow_finding_by_any_with_string
    assert_equal @blink, Book.find_by_any('Blink')
  end
  
  def teardown
    Book.destroy_all
  end
end

class EnumerationWithMultipleAttributesTest < Test::Unit::TestCase
  def setup
    @users_index = create_access_path(:controller => 'users', :action => 'index')
  end
  
  def test_should_not_have_a_controller
    path = AccessPath.new
    assert path.controller.blank?
  end
  
  def test_should_not_have_an_action
    path = AccessPath.new
    assert path.action.blank?
  end
  
  def test_should_have_3_columns
    assert_equal 3, AccessPath.columns.size
  end
  
  def test_should_not_require_a_controller
    path = new_access_path(:controller => nil)
    assert path.valid?
  end
  
  def test_should_not_require_an_action
    path = new_access_path(:action => nil)
    assert path.valid?
  end
  
  def test_should_require_a_unique_controller_and_action
    second_path = new_access_path(:controller => 'users', :action => 'index')
    assert !second_path.valid?
    assert_equal 1, Array(second_path.errors.on(:controller)).size
  end
  
  def test_should_allow_finding_all_by_controller_with_symbol
    assert_equal [@users_index], AccessPath.find_all_by_controller(:users)
  end
  
  def test_should_allow_finding_all_by_controller_with_string
    assert_equal [@users_index], AccessPath.find_all_by_controller('users')
  end
  
  def test_should_allow_finding_all_by_action_with_symbol
    assert_equal [@users_index], AccessPath.find_all_by_action(:index)
  end
  
  def test_should_allow_finding_all_by_action_with_string
    assert_equal [@users_index], AccessPath.find_all_by_action('index')
  end
  
  def test_should_allow_finding_by_controller_with_symbol
    assert_equal @users_index, AccessPath.find_by_controller(:users)
  end
  
  def test_should_allow_finding_by_controller_with_string
    assert_equal @users_index, AccessPath.find_by_controller('users')
  end
  
  def test_should_allow_finding_by_action_with_symbol
    assert_equal @users_index, AccessPath.find_by_action(:index)
  end
  
  def test_should_allow_finding_by_action_with_string
    assert_equal @users_index, AccessPath.find_by_action('index')
  end
  
  def test_should_allow_finding_by_action_with_nil
    users = create_access_path(:id => 2, :controller => 'users', :action => nil)
    assert_equal users, AccessPath.find_by_action(nil)
  end
  
  def test_should_find_indexed_model_with_a_symbol
    assert_equal @users_index, AccessPath[:users, :index]
  end
  
  def test_should_find_indexed_model_with_a_string
    assert_equal @users_index, AccessPath['users', 'index']
  end
  
  def test_should_find_index_model_with_missing_attribute
    users = create_access_path(:id => 2, :controller => 'users', :action => nil)
    assert_equal @users_index, AccessPath['users']
  end
  
  def test_should_allow_finding_by_any_with_symbol
    assert_equal @users_index, AccessPath.find_by_any(:users, :index)
  end
  
  def test_should_allow_finding_by_any_with_string
    assert_equal @users_index, AccessPath.find_by_any('users', 'index')
  end
  
  def test_should_allow_finding_by_any_with_string_and_missing_attribute
    users = create_access_path(:id => 2, :controller => 'users', :action => nil)
    assert_equal @users_index, AccessPath.find_by_any('users')
  end
  
  def test_should_not_respond_to_identifier_queries
    assert !@users_index.respond_to?(:users?)
    assert !@users_index.respond_to?(:index?)
    assert !@users_index.respond_to?(:users_index?)
  end
  
  def test_should_stringify_enumeration_attributes
    assert_equal 'users, index', @users_index.to_s
    assert_equal 'users, index', @users_index.to_str
  end
  
  def test_should_arify_enumeration_attributes
    assert_equal %w(users index), @users_index.to_ary
  end
  
  def test_should_not_be_able_to_compare_with_strings
    assert 'users, index' != @users_index
    assert @users_index != 'users, index'
  end
  
  def test_should_be_able_to_compare_with_arrays
    assert %w(users index) == @users_index.to_ary
    assert @users_index.to_ary == %w(users index)
  end
  
  def teardown
    AccessPath.destroy_all
  end
end

class ModelWithoutEnumerationTest < Test::Unit::TestCase
  def test_should_not_be_an_enumeration
    assert !Car.enumeration?
  end
end
