module ActsAsEnumeration
  module Extensions #:nodoc:
    # Adds support for using the enumeration value in dynamic finders and
    # conditions.  For example,
    # 
    #   class Color < ActiveRecord::Base
    #     acts_as_enumeration
    #     
    #     create :id => 1, :name => 'red'
    #     create :id => 2, :name => 'blue'
    #     create :id => 3, :name => 'green'
    #   end
    #   
    #   Car.find_by_color('red')
    #   Car.find(:conditions => {:color => 'red'})
    #   Car.update_all({:color => 'red'})
    module BaseConditions
      def self.extended(base) #:nodoc:
        class << base
          alias_method_chain :construct_attributes_from_arguments, :enumerations
          alias_method_chain :sanitize_sql_hash_for_conditions, :enumerations
          alias_method_chain :sanitize_sql_hash_for_assignment, :enumerations
          alias_method_chain :all_attributes_exists?, :enumerations
        end
      end
      
      # Add support for dynamic finders
      def construct_attributes_from_arguments_with_enumerations(attribute_names, arguments)
        attributes = construct_attributes_from_arguments_without_enumerations(attribute_names, arguments)
        attribute_names.each_with_index do |name, idx|
          primary_key_name, value = enumeration_value_for(name, arguments[idx])
          if value
            attributes.delete(name)
            attributes[primary_key_name] = value
          end
        end
        
        attributes
      end
      
      # Sanitizes a hash of attribute/value pairs into SQL conditions for a WHERE clause.
      def sanitize_sql_hash_for_conditions_with_enumerations(attrs)
        replace_enumeration_values_in_hash(attrs)
        sanitize_sql_hash_for_conditions_without_enumerations(attrs)
      end
      
      # Sanitizes a hash of attribute/value pairs into SQL conditions for a SET clause.
      def sanitize_sql_hash_for_assignment_with_enumerations(attrs)
        replace_enumeration_values_in_hash(attrs, false)
        sanitize_sql_hash_for_assignment_without_enumerations(attrs)
      end
      
      # Finds all of the attributes that are enumerations are replaces them
      # with the correct enumeration identifier
      def replace_enumeration_values_in_hash(attrs, allow_multiple = true) #:nodoc:
        attrs.each do |attr, value|
          primary_key_name, value = enumeration_value_for(attr, value, allow_multiple)
          if value
            attrs.delete(attr)
            attrs[primary_key_name] = value
          end
        end
      end
      
      # Make sure dynamic finders don't fail since it won't find the association
      # name in its columns
      def all_attributes_exists_with_enumerations?(attribute_names)
        exists = all_attributes_exists_without_enumerations?(attribute_names)
        exists ||= attribute_names.all? do |name|
          column_methods_hash.include?(name.to_sym) || is_enumeration?(name)
        end
      end
      
      # Find the actual enumeration value and class for the given association
      # name
      def enumeration_value_for(name, value, allow_multiple = true)
        if (reflection = reflect_on_association(name.to_sym)) && reflection.klass.enumeration?
          klass = reflection.klass
          [reflection.primary_key_name, (allow_multiple && value.is_a?(Array)) ? value.map {|value| klass[value]} : klass[value]]
        end
      end
      
      # Is the given association name an enumeration?
      def is_enumeration?(name)
        (reflection = reflect_on_association(name.to_sym)) && reflection.klass.enumeration?
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  extend ActsAsEnumeration::Extensions::BaseConditions
end
