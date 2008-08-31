require File.dirname(__FILE__) + '/../test_helper'

class XmlSerializerAttributeWithEnumerationTest < Test::Unit::TestCase
  def setup
    @color = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => 'red')
    @attribute = ActiveRecord::XmlSerializer::Attribute.new('color', @car)
  end
  
  def test_should_have_a_string_type
    assert_equal :string, @attribute.type
  end
  
  def test_should_use_enumeration_value
    assert_equal 'red', @attribute.value
  end
  
  def teardown
    Color.destroy_all
  end
end

class XmlSerializerAttributeWithNilEnumerationTest < Test::Unit::TestCase
  def setup
    @color = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => 'red')
    @attribute = ActiveRecord::XmlSerializer::Attribute.new('manufacturer', @car)
  end
  
  def test_should_have_a_string_type
    assert_equal :string, @attribute.type
  end
  
  def test_should_use_enumeration_value
    assert_nil @attribute.value
  end
  
  def teardown
    Color.destroy_all
  end
end

class XmlSerializerAttributeWithoutEnumerationTest < Test::Unit::TestCase
  def setup
    @color = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => 'red')
    @attribute = ActiveRecord::XmlSerializer::Attribute.new('id', @car)
  end
  
  def test_should_use_column_type
    assert_equal :integer, @attribute.type
  end
  
  def test_should_use_attribute_value
    assert_equal @car.id, @attribute.value
  end
  
  def teardown
    Color.destroy_all
  end
end

class XmlSerializerTest < Test::Unit::TestCase
  def setup
    @color = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => 'red')
  end
  
  def test_should_be_able_to_convert_to_xml
    expected = <<-eos
<?xml version="1.0" encoding="UTF-8"?>
<car>
  <color>red</color>
  <id type="integer">#{@car.id}</id>
  <manufacturer nil="true"></manufacturer>
  <name>Ford Mustang</name>
</car>
    eos
    
    assert_equal expected, @car.to_xml
  end
  
  def teardown
    Color.destroy_all
  end
end
