module EnumerateBy
  module Extensions #:nodoc:
    # Adds support for using enumerators in dynamic finders and conditions.
    # For example suppose the following models are defined:
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
    # Normally, looking up all cars associated with a particular color
    # requires either a join or knowing the id of the color upfront:
    # 
    #   Car.find(:all, :joins => :color, :conditions => {:colors => {:name => 'red}})
    #   Car.find_by_color_id(1)
    # 
    # Instead of doing this manually, the color can be referenced directly
    # via its enumerator like so:
    # 
    #   # With dynamic finders
    #   Car.find_by_color('red')
    #   
    #   # With conditions
    #   Car.all(:conditions => {:color => 'red'})
    #   
    #   # With updates
    #   Car.update_all(:color => 'red')
    # 
    # In the above examples, +color+ is essentially treated like a normal
    # attribute on the class, instead triggering the associated Color record
    # to be looked up and replacing the condition with a +color_id+ condition.
    # 
    # *Note* that this does not add an additional join on the +colors+ table
    # since the lookup of the color's id should be relatively fast when it's
    # cached in-memory.
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
          if options = enumerator_options_for(name, arguments[idx])
            attributes.delete(name)
            attributes.merge!(options)
          end
        end
        
        attributes
      end
      
      # Sanitizes a hash of attribute/value pairs into SQL conditions for a WHERE clause.
      def sanitize_sql_hash_for_conditions_with_enumerations(attrs, *args)
        replace_enumerations_in_hash(attrs)
        sanitize_sql_hash_for_conditions_without_enumerations(attrs, *args)
      end
      
      # Sanitizes a hash of attribute/value pairs into SQL conditions for a SET clause.
      def sanitize_sql_hash_for_assignment_with_enumerations(attrs, *args)
        replace_enumerations_in_hash(attrs, false)
        sanitize_sql_hash_for_assignment_without_enumerations(attrs, *args)
      end
      
      # Make sure dynamic finders don't fail since it won't find the association
      # name in its columns
      def all_attributes_exists_with_enumerations?(attribute_names)
        exists = all_attributes_exists_without_enumerations?(attribute_names)
        exists ||= attribute_names.all? do |name|
          column_methods_hash.include?(name.to_sym) || reflect_on_enumeration(name)
        end
      end
      
      private
        # Finds all of the attributes that are enumerations and replaces them
        # with the correct enumerator id
        def replace_enumerations_in_hash(attrs, allow_multiple = true) #:nodoc:
          attrs.each do |attr, value|
            if options = enumerator_options_for(attr, value, allow_multiple)
              attrs.delete(attr)
              attrs.merge!(options)
            end
          end
        end
        
        # Generates the enumerator lookup options for the given association
        # name and enumerator value.  If the association is *not* for an
        # enumeration, then this will return nil.
        def enumerator_options_for(name, enumerator, allow_multiple = true)
          if reflection = reflect_on_enumeration(name)
            klass = reflection.klass
            attribute = reflection.primary_key_name
            id = if allow_multiple && enumerator.is_a?(Array)
              klass.find_all_by_enumerator!(enumerator).map(&:id)
            else
              klass.find_by_enumerator!(enumerator).id
            end
            
            {attribute => id}
          end
        end
        
        # Attempts to find an association with the given name *and* represents
        # an enumeration
        def reflect_on_enumeration(name)
          reflection = reflect_on_association(name.to_sym)
          reflection if reflection && reflection.klass.enumeration?
        end
    end
  end
end

ActiveRecord::Base.class_eval do
  extend EnumerateBy::Extensions::BaseConditions
end
