require File.dirname(__FILE__) + '/../test_helper'

class ModelWithBelongsToAssociationTest < Test::Unit::TestCase
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
    @car.color = 'green'
    assert_nil @car.color
  end
  
  def test_should_track_associations
    expected = {'color_id' => 'color', 'manufacturer_id' => 'manufacturer'}
    assert_equal expected, Car.enumeration_associations
  end
  
  def teardown
    Color.destroy_all
  end
end

class EnumerationWithBelongsToAssociationTest < Test::Unit::TestCase
  def setup
    @united_states = create_country(:id => 1, :name => 'United States')
    @canada = create_country(:id => 2, :name => 'Canada')
    @california = create_region(:name => 'California', :country => nil)
    @california.country_id = @united_states.id
  end
  
  def test_should_find_association_from_id
    assert_equal @united_states, @california.country
  end
  
  def test_should_use_the_cached_association
    assert_same @united_states, @california.country
  end
  
  def test_should_infer_enumeration_from_a_symbolized_name
    @california.country = :Canada
    assert_equal @canada, @california.country
  end
  
  def test_should_infer_enumeration_from_a_stringified_name
    @california.country = 'Canada'
    assert_equal @canada, @california.country
  end
  
  def test_should_infer_enumeration_from_an_id
    @california.country = 2
    assert_equal @canada, @california.country
  end
  
  def test_should_infer_enumeration_from_a_record
    @california.country = @canada
    assert_equal @canada, @california.country
  end
  
  def test_should_use_nil_if_enumeration_does_not_exist
    @california.country = 'Nonexistent'
    assert_nil @california.country
  end
  
  def teardown
    Region.destroy_all
    Country.destroy_all
  end
end

class ModelWithBelongsToAssociationAsAClassTest < Test::Unit::TestCase
  def setup
    @red = create_color(:id => 1, :name => 'red')
    @blue = create_color(:id => 2, :name => 'blue')
    @red_car = create_car(:name => 'Ford Mustang', :color_id => 1)
    @blue_car = create_car(:name => 'Ford Mustang', :color_id => 2)
    
    @ford = create_car(:name => 'Ford Mustang', :color_id => 1, :manufacturer_id => 1)
    @chevy = create_car(:name => 'Chevy Silverado', :color_id => 1, :manufacturer_id => 2)
  end
  
  def test_should_have_a_named_scope_for_finding_a_single_enumeration_identifier
    assert_equal [@ford], Car.with_manufacturer('ford')
    assert_equal [@chevy], Car.with_manufacturer('chevy')
  end
  
  def test_should_have_a_named_scope_for_finding_multiple_enumeration_identifiers
    assert_equal [@ford, @chevy], Car.with_manufacturers('ford', 'chevy')
  end
  
  def teardown
    Color.destroy_all
  end
end

class EnumerationWithBelongsToAssociationAsAClassTest < Test::Unit::TestCase
  def setup
    @united_states = create_country(:id => 1, :name => 'United States')
    @canada = create_country(:id => 2, :name => 'Canada')
    
    @california = create_region(:id => 1, :name => 'California', :country => @united_states)
    @quebec = create_region(:id => 2, :name => 'Quebec', :country => @canada)
  end
  
  def test_should_have_a_named_scope_for_finding_a_single_enumeration_identifier
    assert_equal [@california], Region.with_country('United States')
    assert_equal [@quebec], Region.with_country('Canada')
  end
  
  def test_should_have_a_named_scope_for_finding_multiple_enumeration_identifiers
    assert_equal [@california, @quebec], Region.with_countries('United States', 'Canada')
  end
  
  def teardown
    Region.destroy_all
    Country.destroy_all
  end
end

class ModelWithPolymorphicBelongsToAssociationTest < Test::Unit::TestCase
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

class EnumerationWithHasOneModelTest < Test::Unit::TestCase
  def setup
    @united_states = create_country(:name => 'United States')
    @john_smith = create_ambassador(:name => 'John Doe', :country => 'United States')
  end
  
  def test_should_have_an_association
    assert_equal @john_smith, @united_states.ambassador
  end
  
  def test_should_automatically_reload_association
    @john_smith.destroy
    assert_nil @united_states.ambassador
  end
  
  def teardown
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

class EnumerationWithHasManyModelAssociationTest < Test::Unit::TestCase
  def setup
    @manufacturer = Manufacturer[:ford]
    @first_car = create_car(:manufacturer => @manufacturer)
    
    # Load the association
    @manufacturer.cars.inspect
  end
  
  def test_should_automatically_reload_associations
    second_car = create_car(:manufacturer => @manufacturer)
    assert_equal [@first_car, second_car], @manufacturer.cars
  end
end

class ModelWithHasManyModelAssociationTest < Test::Unit::TestCase
  def setup
    @car = create_car
    @first_passenger = create_passenger(:car => @car)
    
    # Load the association
    @car.passengers.inspect
  end
  
  def test_should_not_automatically_reload_associations
    create_passenger(:car => @car)
    assert_equal [@first_passenger], @car.passengers
  end
end
