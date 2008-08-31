module PluginAWeek #:nodoc:
  module ActsAsEnumeration
    module Extensions #:nodoc:
      # Adds support for automatically converting enumeration attributes to the
      # value represented by them.
      # 
      # == Examples
      # 
      # Suppose the following models are defined:
      # 
      #   class Color < ActiveRecord::Base
      #     acts_as_enumeration
      #     
      #     create :id => 1, :name => 'red'
      #     create :id => 2, :name => 'blue'
      #     create :id => 3, :name => 'green'
      #   end
      #   
      #   class Car < ActiveRecord::Base
      #     belongs_to :color
      #   end
      # 
      # Given the above:
      # 
      #   car = Car.new(:color => 'red')  # => #<Car id: nil, color: "red">
      #   car.save!                       # => #<Car id: 1, color: "red">
      #   car.to_xml
      # 
      # ...would convert to:
      # 
      #   <car>
      #     <id type="integer">1</id>
      #     <color>red</color>
      #   </car>
      # 
      # The same goes for JSON conversion:
      # 
      #   car.to_json
      # 
      # ...would convert to:
      # 
      #   {
      #     id: 1
      #     color: "red"
      #   }
      # 
      # == Conversion options
      # 
      # The actual conversion of enumerations can be controlled using the
      # following options:
      # 
      #   car.to_json                           # => {id: 1, color: "red"}
      #   car.to_json(:enumerations => false)   # => {id: 1, color_id: 1}
      #   car.to_json(:only => [:color_id])     # => {color_id: 1}
      #   car.to_json(:only => [:color])        # => {color: "red"}
      #   car.to_json(:include => :color)       # => {id: 1, color_id: 1, color: {id: 1, name: "red"}}
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
          attributes = serializable_attribute_names_without_enumerations
          
          # Adjust the serializable attributes by adding/removing any enumeration
          # association names specified in :only/:except, respectively
          if options[:only]
            attributes |= Array(options[:only]).map(&:to_s) & @record.class.enumeration_associations.values
            attributes.sort!
          elsif options[:except]
            attributes -= @record.class.enumeration_associations.invert.values_at(*Array(options[:except]).map(&:to_s))
          end
          
          # Convert enumeration attributes to their association names
          attributes.map! {|attribute| enumeration_association_for(attribute) || attribute} if convert_enumerations?
          
          attributes
        end
        
        # Automatically casts enumerations to their public values
        def serializable_record_with_enumerations
          returning(serializable_record = serializable_record_without_enumerations) do
            serializable_record.each do |attribute, value|
              # Enumerations that aren't marked as :include associations should
              # be converted to their real value
              serializable_record[attribute] = value.enumeration_value if typecast_as_enumeration?(attribute, value)
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
          def convert_enumeration?(attribute)
            !(options[:only] && Array(options[:only]).map(&:to_s).include?(attribute))
          end
          
          # Gets the association name for the given enumeration attribute, if
          # one exists
          def enumeration_association_for(attribute)
            if convert_enumeration?(attribute) && association = @record.class.enumeration_associations[attribute]
              association unless include_enumeration?(association)
            end
          end
          
          # Is the given enumeration attribute being included as a whole record
          # instead of just an individual attribute?
          def include_enumeration?(association)
            options[:include] && Array(options[:include]).map(&:to_s).include?(association)
          end
          
          # Should the given value be typecasted as an enumeration attribute?
          def typecast_as_enumeration?(association, value)
            value.is_a?(ActiveRecord::Base) && value.class.enumeration? && !include_enumeration?(association)
          end
      end
    end
  end
end

ActiveRecord::Serialization::Serializer.class_eval do
  include PluginAWeek::ActsAsEnumeration::Extensions::Serializer
end
