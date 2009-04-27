require File.dirname(__FILE__) + '/../test_helper'

class SerializerByDefaultTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => @red)
    @serializer = ActiveRecord::Serialization::Serializer.new(@car)
  end
  
  def test_should_include_enumerations_in_serializable_attribute_names
    assert_equal %w(color feature_id feature_type id name), @serializer.serializable_attribute_names
  end
  
  def test_should_typecast_serializable_record
    expected = {
      'color' => 'red',
      'feature_id' => nil,
      'feature_type' => nil,
      'id' => @car.id,
      'name' => 'Ford Mustang'
    }
    
    assert_equal expected, @serializer.serializable_record
  end
end

class SerializerWithoutEnumerationsTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => @red)
    @serializer = ActiveRecord::Serialization::Serializer.new(@car, :enumerations => false)
  end
  
  def test_should_not_include_enumerations_in_serializable_attribute_names
    assert_equal %w(color_id feature_id feature_type id name), @serializer.serializable_attribute_names
  end
  
  def test_should_not_typecast_serializable_record
    expected = {
      'color_id' => @red.id,
      'feature_id' => nil,
      'feature_type' => nil,
      'id' => @car.id,
      'name' => 'Ford Mustang'
    }
    
    assert_equal expected, @serializer.serializable_record
  end
end

class SerializerWithOnlyEnumerationAttributeTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => @red)
    @serializer = ActiveRecord::Serialization::Serializer.new(@car, :only => [:id, :color_id])
  end
  
  def test_should_not_include_enumeration_in_serializable_attribute_names
    assert_equal %w(color_id id), @serializer.serializable_attribute_names
  end
  
  def test_should_not_typecast_serializable_record
    expected = {
      'color_id' => @red.id,
      'id' => @car.id
    }
    
    assert_equal expected, @serializer.serializable_record
  end
end

class SerializerWithOnlyEnumerationAssociationTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => @red)
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
end

class SerializerWithExceptEnumerationAttributeTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => @red)
    @serializer = ActiveRecord::Serialization::Serializer.new(@car, :except => :color_id)
  end
  
  def test_should_not_include_enumeration_in_serializable_attribute_names
    assert_equal %w(feature_id feature_type id name), @serializer.serializable_attribute_names
  end
  
  def test_should_not_include_enumeration_in_serializable_record
    expected = {
      'feature_id' => nil,
      'feature_type' => nil,
      'id' => @car.id,
      'name' => 'Ford Mustang'
    }
    
    assert_equal expected, @serializer.serializable_record
  end
end

class SerializerWithExceptEnumerationAssociationTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => @red)
    @serializer = ActiveRecord::Serialization::Serializer.new(@car, :except => :color)
  end
  
  def test_should_not_include_enumeration_in_serializable_attribute_names
    assert_equal %w(feature_id feature_type id name), @serializer.serializable_attribute_names
  end
  
  def test_should_not_include_enumeration_in_serializable_record
    expected = {
      'feature_id' => nil,
      'feature_type' => nil,
      'id' => @car.id,
      'name' => 'Ford Mustang'
    }
    
    assert_equal expected, @serializer.serializable_record
  end
end

class SerializerWithIncludeEnumerationTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => @red)
    @serializer = ActiveRecord::Serialization::Serializer.new(@car, :include => :color)
  end
  
  def test_should_not_include_enumeration_in_serializable_attribute_names
    assert_equal %w(color_id feature_id feature_type id name), @serializer.serializable_attribute_names
  end
  
  def test_should_include_entire_enumeration_in_serializable_record
    expected = {
      :color => {
        'html' => nil,
        'id' => @red.id,
        'name' => 'red'
      },
      'color_id' => @red.id,
      'feature_id' => nil,
      'feature_type' => nil,
      'id' => @car.id,
      'name' => 'Ford Mustang'
    }
    
    assert_equal expected, @serializer.serializable_record
  end
end
