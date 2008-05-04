require File.dirname(__FILE__) + '/../test_helper'

class EnumerationWithBelongsToAssociationTest < Test::Unit::TestCase
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

class EnumerationWithBelongsToAssociationAsAClassTest < Test::Unit::TestCase
  def setup
    @red = create_color(:id => 1, :name => 'red')
    @blue = create_color(:id => 2, :name => 'blue')
    @red_car = create_car(:name => 'Ford Mustang', :color_id => 1)
    @blue_car = create_car(:name => 'Ford Mustang', :color_id => 2)
    
    @ford = create_car(:name => 'Ford Mustang', :color_id => 1, :manufacturer_id => 1)
    @chevy = create_car(:name => 'Chevy Silverado', :color_id => 1, :manufacturer_id => 2)
  end
  
  def test_should_have_a_named_scope_for_finding_a_single_enumeration_identifier
    assert_equal [@ford], Car.with_manufacturer(:ford)
    assert_equal [@chevy], Car.with_manufacturer(:chevy)
  end
  
  def test_should_have_a_named_scope_for_finding_multiple_enumeration_identifiers
    assert_equal [@ford, @chevy], Car.with_manufacturers(:ford, :chevy)
  end
  
  def teardown
    Color.destroy_all
    Car.destroy_all
  end
end

class EnumerationWithPolymorphicBelongsToAssociationTest < Test::Unit::TestCase
  def test_should_not_create_a_named_scope
    assert !Car.respond_to?(:with_addressable)
  end
end

class EnumerationWithHasOneAssociationTest < Test::Unit::TestCase
  def setup
    @united_states = create_country(:name => 'United States')
    @english = create_language(:id => 1, :name => 'English', :country => 'United States')
  end
  
  def test_should_use_the_cached_association
    assert_same @english, @united_states.language
  end
  
  def teardown
    Language.destroy_all
    Country.destroy_all
  end
end

class EnumerationWithHasManyAssociationTest < Test::Unit::TestCase
  def setup
    @united_states = create_country(:name => 'United States')
    @new_jersey = create_region(:id => 1, :name => 'New Jersey', :country => 'United States')
    @new_york = create_region(:id => 2, :name => 'New York', :country => 'United States')
  end
  
  def test_should_use_the_cached_associations
    assert_equal [@new_jersey, @new_york], @united_states.regions
  end
  
  def teardown
    Region.destroy_all
    Country.destroy_all
  end
end
