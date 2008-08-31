require File.dirname(__FILE__) + '/../test_helper'

class SerializerByDefaultTest < Test::Unit::TestCase
  def setup
    @color = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => 'red')
    @serializer = ActiveRecord::Serialization::Serializer.new(@car)
  end
  
  def test_should_include_enumerations_in_serializable_attribute_names
    assert_equal %w(color id manufacturer name), @serializer.serializable_attribute_names
  end
  
  def test_should_typecast_serializable_record
    expected = {
      'color' => 'red',
      'id' => @car.id,
      'manufacturer' => nil,
      'name' => 'Ford Mustang'
    }
    
    assert_equal expected, @serializer.serializable_record
  end
  
  def teardown
    Color.destroy_all
  end
end

class SerializerWithoutEnumerationsTest < Test::Unit::TestCase
  def setup
    @color = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => 'red')
    @serializer = ActiveRecord::Serialization::Serializer.new(@car, :enumerations => false)
  end
  
  def test_should_not_include_enumerations_in_serializable_attribute_names
    assert_equal %w(color_id id manufacturer_id name), @serializer.serializable_attribute_names
  end
  
  def test_should_not_typecast_serializable_record
    expected = {
      'color_id' => @color.id,
      'id' => @car.id,
      'manufacturer_id' => nil,
      'name' => 'Ford Mustang'
    }
    
    assert_equal expected, @serializer.serializable_record
  end
  
  def teardown
    Color.destroy_all
  end
end

class SerializerWithOnlyEnumerationAttributeTest < Test::Unit::TestCase
  def setup
    @color = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => 'red')
    @serializer = ActiveRecord::Serialization::Serializer.new(@car, :only => [:id, :color_id])
  end
  
  def test_should_not_include_enumeration_in_serializable_attribute_names
    assert_equal %w(color_id id), @serializer.serializable_attribute_names
  end
  
  def test_should_not_typecast_serializable_record
    expected = {
      'color_id' => @color.id,
      'id' => @car.id
    }
    
    assert_equal expected, @serializer.serializable_record
  end
  
  def teardown
    Color.destroy_all
  end
end

class SerializerWithOnlyEnumerationAssociationTest < Test::Unit::TestCase
  def setup
    @color = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => 'red')
    @serializer = ActiveRecord::Serialization::Serializer.new(@car, :only => [:color, :id])
  end
  
  def test_should_include_enumeration_in_serializable_attribute_names
    assert_equal %w(color id), @serializer.serializable_attribute_names
  end
  
  def test_should_typecast_serializable_record
    expected = {
      'color' => 'red',
      'id' => @car.id
    }
    
    assert_equal expected, @serializer.serializable_record
  end
  
  def teardown
    Color.destroy_all
  end
end

class SerializerWithExceptEnumerationAttributeTest < Test::Unit::TestCase
  def setup
    @color = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => 'red')
    @serializer = ActiveRecord::Serialization::Serializer.new(@car, :except => :color_id)
  end
  
  def test_should_not_include_enumeration_in_serializable_attribute_names
    assert_equal %w(id manufacturer name), @serializer.serializable_attribute_names
  end
  
  def test_should_not_include_enumeration_in_serializable_record
    expected = {
      'id' => @car.id,
      'manufacturer' => nil,
      'name' => 'Ford Mustang'
    }
    
    assert_equal expected, @serializer.serializable_record
  end
  
  def teardown
    Color.destroy_all
  end
end

class SerializerWithExceptEnumerationAssociationTest < Test::Unit::TestCase
  def setup
    @color = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => 'red')
    @serializer = ActiveRecord::Serialization::Serializer.new(@car, :except => :color)
  end
  
  def test_should_not_include_enumeration_in_serializable_attribute_names
    assert_equal %w(id manufacturer name), @serializer.serializable_attribute_names
  end
  
  def test_should_not_include_enumeration_in_serializable_record
    expected = {
      'id' => @car.id,
      'manufacturer' => nil,
      'name' => 'Ford Mustang'
    }
    
    assert_equal expected, @serializer.serializable_record
  end
  
  def teardown
    Color.destroy_all
  end
end

class SerializerWithIncludeEnumerationTest < Test::Unit::TestCase
  def setup
    @color = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => 'red')
    @serializer = ActiveRecord::Serialization::Serializer.new(@car, :include => :color)
  end
  
  def test_should_not_include_enumeration_in_serializable_attribute_names
    assert_equal %w(color_id id manufacturer name), @serializer.serializable_attribute_names
  end
  
  def test_should_include_entire_enumeration_in_serializable_record
    expected = {
      :color => {
        'id' => @color.id,
        'name' => 'red'
      },
      'color_id' => @color.id,
      'id' => @car.id,
      'manufacturer' => nil,
      'name' => 'Ford Mustang'
    }
    
    assert_equal expected, @serializer.serializable_record
  end
  
  def teardown
    Color.destroy_all
  end
end
