module PluginAWeek #:nodoc:
  module Acts #:nodoc:
    module Enumeration #:nodoc:
      module Extensions #:nodoc:
        # Adds support for using the enumerated value in dynamic finders and
        # conditions, such as:
        # 
        #   Car.find_by_color(:red)
        #   Car.find(:conditions => {:color => :red})
        module BaseConditions
          def self.extended(base) #:nodoc:
            class << base
              alias_method_chain :construct_attributes_from_arguments, :enumerations
              alias_method_chain :sanitize_sql_hash, :enumerations
              alias_method_chain :all_attributes_exists?, :enumerations
            end
          end
          
          # Add support for dynamic finders
          def construct_attributes_from_arguments_with_enumerations(attribute_names, arguments)
            attributes = construct_attributes_from_arguments_without_enumerations(attribute_names, arguments)
            attribute_names.each_with_index do |name, idx|
              primary_key_name, value = enumerated_value_for(name, arguments[idx])
              if value
                attributes.delete(name)
                attributes[primary_key_name] = value
              end
            end
            
            attributes
          end
          
          # Add support for the conditions hash
          def sanitize_sql_hash_with_enumerations(attrs)
            attrs.each do |attr, value|
              primary_key_name, value = enumerated_value_for(attr, value)
              if value
                attrs.delete(attr)
                attrs[primary_key_name] = value
              end
            end
            
            sanitize_sql_hash_without_enumerations(attrs)
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
          def enumerated_value_for(name, value)
            if (reflection = reflect_on_association(name.to_sym)) && reflection.klass.enumeration?
              klass = reflection.klass
              return reflection.primary_key_name, klass[value]
            end
          end
          
          # Is the given association name an enumeration?
          def is_enumeration?(name)
            (reflection = reflect_on_association(name.to_sym)) && reflection.klass.enumeration?
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  extend PluginAWeek::Acts::Enumeration::Extensions::BaseConditions
end