module EnumerateBy
  module Extensions #:nodoc:
    # Adds support for automatically converting enumeration attributes to the
    # value represented by them.
    # 
    # == Examples
    # 
    # Suppose the following models are defined:
    # 
    #   class Color < ActiveRecord::Base
    #     enumerate_by :name
    #     
    #     bootstrap(
    #       {:id => 1, :name => 'red'},
    #       {:id => 2, :name => 'blue'},
    #       {:id => 3, :name => 'green'}
    #     )
    #   end
    #   
    #   class Car < ActiveRecord::Base
    #     belongs_to :color
    #   end
    # 
    # Given the above, the enumerator for the car will be automatically
    # used for serialization instead of the foreign key like so:
    # 
    #   car = Car.create(:color => 'red')  # => #<Car id: 1, color_id: 1>
    #   car.to_xml  # => "<car><id type=\"integer\">1</id><color>red</color></car>"
    #   car.to_json # => "{id: 1, color: \"red\"}"
    # 
    # == Conversion options
    # 
    # The actual conversion of enumeration associations can be controlled
    # using the following options:
    # 
    #   car.to_json                           # => "{id: 1, color: \"red\"}"
    #   car.to_json(:enumerations => false)   # => "{id: 1, color_id: 1}"
    #   car.to_json(:only => [:color_id])     # => "{color_id: 1}"
    #   car.to_json(:only => [:color])        # => "{color: \"red\"}"
    #   car.to_json(:include => :color)       # => "{id: 1, color_id: 1, color: {id: 1, name: \"red\"}}"
    # 
    # As can be seen from above, enumeration attributes can either be treated
    # as pseudo-attributes on the record or its actual association.
    module Serializer
      def self.included(base) #:nodoc:
        base.class_eval do
          alias_method_chain :serializable_attribute_names, :enumerations
          alias_method_chain :serializable_record, :enumerations
        end
      end
      
      # Automatically converted enumeration attributes to their association
      # names so that they *appear* as attributes
      def serializable_attribute_names_with_enumerations
        attribute_names = serializable_attribute_names_without_enumerations
        
        # Adjust the serializable attributes by converting primary keys for
        # enumeration associations to their association name (where possible)
        if convert_enumerations?
          @only_attributes = Array(options[:only]).map(&:to_s)
          @include_associations = Array(options[:include]).map(&:to_s)
          
          attribute_names.map! {|attribute| enumeration_association_for(attribute) || attribute}
          attribute_names |= @record.class.enumeration_associations.values & @only_attributes
          attribute_names.sort!
          attribute_names -= options[:except].map(&:to_s) unless options[:only]
        end
        
        attribute_names
      end
      
      # Automatically casts enumerations to their public values
      def serializable_record_with_enumerations
        returning(serializable_record = serializable_record_without_enumerations) do
          serializable_record.each do |attribute, value|
            # Typecast to enumerator value
            serializable_record[attribute] = value.enumerator if typecast_to_enumerator?(attribute, value)
          end if convert_enumerations?
        end
      end
      
      private
        # Should enumeration attributes be automatically converted based on
        # the serialization configuration
        def convert_enumerations?
          options[:enumerations] != false
        end
        
        # Should the given attribute be converted to the actual enumeration?
        def convert_to_enumeration?(attribute)
          !@only_attributes.include?(attribute)
        end
        
        # Gets the association name for the given enumeration attribute, if
        # one exists
        def enumeration_association_for(attribute)
          association = @record.class.enumeration_associations[attribute]
          association if association && convert_to_enumeration?(attribute) && !include_enumeration?(association)
        end
        
        # Is the given enumeration attribute being included as a whole record
        # instead of just an individual attribute?
        def include_enumeration?(association)
          @include_associations.include?(association)
        end
        
        # Should the given value be typecasted to its enumerator value?
        def typecast_to_enumerator?(association, value)
          value.is_a?(ActiveRecord::Base) && value.class.enumeration? && !include_enumeration?(association)
        end
    end
  end
end

ActiveRecord::Serialization::Serializer.class_eval do
  include EnumerateBy::Extensions::Serializer
end
