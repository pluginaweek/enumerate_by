require File.dirname(__FILE__) + '/../test_helper'

class ModelWithBelongsToAssociationTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @green = create_color(:name => 'green')
    @car = create_car(:name => 'Ford Mustang', :color => nil)
  end
  
  def test_should_find_association_from_id
    @car.color_id = @red.id
    assert_equal @red, @car.color
  end
  
  def test_should_find_association_from_enumerator
    @car.color = 'green'
    assert_equal @green, @car.color
  end
  
  def test_should_find_assocation_from_record
    @car.color = @green
    assert_equal @green, @car.color
  end
  
  def test_should_use_nil_if_enumeration_does_not_exist
    assert_nothing_raised { @car.color = 'blue' }
    assert_nil @car.color
  end
  
  def test_should_allow_nil
    assert_nothing_raised { @car.color = nil }
    assert_nil @car.color
  end
  
  def test_should_track_associations
    expected = {'color_id' => 'color', 'legacy_color_id' => 'legacy_color'}
    assert_equal expected, Car.enumeration_associations
  end
end

class ModelWithEnumerationScopesTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @blue = create_color(:name => 'blue')
    @red_car = create_car(:name => 'Ford Mustang', :color => @red)
    @blue_car = create_car(:name => 'Ford Mustang', :color => @blue)
  end
  
  def test_should_have_inclusion_scope_for_single_enumerator
    assert_equal [@red_car], Car.with_color('red')
    assert_equal [@blue_car], Car.with_color('blue')
  end
  
  def test_should_have_inclusion_scope_for_multiple_enumerators
    assert_equal [@red_car, @blue_car], Car.with_color('red', 'blue')
  end
  
  def test_should_have_exclusion_scope_for_single_enumerator
    assert_equal [@blue_car], Car.without_color('red')
    assert_equal [@red_car], Car.without_color('blue')
  end
  
  def test_should_have_exclusion_scope_for_multiple_enumerators
    assert_equal [], Car.without_colors('red', 'blue')
  end
end

class ModelWithPolymorphicBelongsToAssociationTest < ActiveRecord::TestCase
  def test_should_not_create_named_scopes
    assert !Car.respond_to?(:with_feature)
    assert !Car.respond_to?(:with_features)
    assert !Car.respond_to?(:without_feature)
    assert !Car.respond_to?(:without_features)
  end
end

class ModelWithEnumerationScopesUsingCustomPrimaryKeyTest < ActiveRecord::TestCase
  def setup
    @red = create_legacy_color(:name => 'red')
    @blue = create_legacy_color(:name => 'blue')
    @red_car = create_car(:name => 'Ford Mustang', :legacy_color => @red)
    @blue_car = create_car(:name => 'Ford Mustang', :legacy_color => @blue)
  end
  
  def test_should_have_inclusion_scope_for_single_enumerator
    assert_equal [@red_car], Car.with_legacy_color('red')
    assert_equal [@blue_car], Car.with_legacy_color('blue')
  end
  
  def test_should_have_inclusion_scope_for_multiple_enumerators
    assert_equal [@red_car, @blue_car], Car.with_legacy_color('red', 'blue')
  end
  
  def test_should_have_exclusion_scope_for_single_enumerator
    assert_equal [@blue_car], Car.without_legacy_color('red')
    assert_equal [@red_car], Car.without_legacy_color('blue')
  end
  
  def test_should_have_exclusion_scope_for_multiple_enumerators
    assert_equal [], Car.without_legacy_colors('red', 'blue')
  end
end
