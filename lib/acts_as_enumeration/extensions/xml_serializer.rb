module PluginAWeek #:nodoc:
  module ActsAsEnumeration
    module Extensions #:nodoc:
      module XmlSerializer #:nodoc:
        # Adds support for xml serialization of enumerations as attributes
        module Attribute
          def self.included(base) #:nodoc:
            base.class_eval do
              alias_method_chain :compute_type, :enumerations
              alias_method_chain :compute_value, :enumerations
            end
          end
          
          protected
            # Enumeration types are always strings
            def compute_type_with_enumerations
              enumeration? ? :string : compute_type_without_enumerations
            end
            
            # Gets the real value representing the enumeration
            def compute_value_with_enumerations
              if enumeration?
                value = @record.send(name)
                value.enumeration_value if value
              else
                compute_value_without_enumerations
              end
            end
            
            # Is this attribute an enumeration association?
            def enumeration?
              @enumeration ||= @record.enumeration_associations.value?(name)
            end
        end
      end
    end
  end
end

ActiveRecord::XmlSerializer::Attribute.class_eval do
  include PluginAWeek::ActsAsEnumeration::Extensions::XmlSerializer::Attribute
end
