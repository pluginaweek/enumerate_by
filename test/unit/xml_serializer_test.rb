require File.dirname(__FILE__) + '/../test_helper'

class XmlSerializerAttributeWithEnumerationTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => @red)
    @attribute = ActiveRecord::XmlSerializer::Attribute.new('color', @car)
  end
  
  def test_should_have_a_string_type
    assert_equal :string, @attribute.type
  end
  
  def test_should_use_enumerator
    assert_equal 'red', @attribute.value
  end
end

class XmlSerializerAttributeWithNilEnumerationTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => nil)
    @attribute = ActiveRecord::XmlSerializer::Attribute.new('color', @car)
  end
  
  def test_should_have_a_string_type
    assert_equal :string, @attribute.type
  end
  
  def test_should_use_nil
    assert_nil @attribute.value
  end
end

class XmlSerializerAttributeWithoutEnumerationTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => @red)
    @attribute = ActiveRecord::XmlSerializer::Attribute.new('id', @car)
  end
  
  def test_should_use_column_type
    assert_equal :integer, @attribute.type
  end
  
  def test_should_use_attribute_value
    assert_equal @car.id, @attribute.value
  end
end

class XmlSerializerTest < ActiveRecord::TestCase
  def setup
    @red = create_color(:name => 'red')
    @car = create_car(:name => 'Ford Mustang', :color => @red)
  end
  
  def test_should_be_able_to_convert_to_xml
    expected = <<-eos
<?xml version="1.0" encoding="UTF-8"?>
<car>
  <color>red</color>
  <feature-id type="integer" nil="true"></feature-id>
  <feature-type nil="true"></feature-type>
  <id type="integer">#{@car.id}</id>
  <legacy-color nil="true"></legacy-color>
  <name>Ford Mustang</name>
</car>
    eos
    
    assert_equal expected, @car.to_xml
  end
end

class XmlSerializerWithNumericEnumeratorAttributeTest < ActiveRecord::TestCase
  def setup
    @engine = create_car_part(:name => 'engine', :number => 123321)
    @order = create_order(:state => 'pending', :car_part => @engine)
  end
  
  def test_should_be_able_to_convert_to_xml
    expected = <<-eos
<?xml version="1.0" encoding="UTF-8"?>
<order>
  <car-part type="integer">123321</car-part>
  <id type="integer">#{@order.id}</id>
  <state>pending</state>
</order>
    eos
    
    assert_equal expected, @order.to_xml
  end
end
