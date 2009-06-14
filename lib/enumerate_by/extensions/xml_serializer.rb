module EnumerateBy
  module Extensions #:nodoc:
    module XmlSerializer #:nodoc:
      # Adds support for xml serialization of enumeration associations as
      # attributes
      module Attribute
        def self.included(base) #:nodoc:
          base.class_eval do
            alias_method_chain :compute_type, :enumerations
            alias_method_chain :compute_value, :enumerations
          end
        end
        
        protected
          # Enumerator types are always strings
          def compute_type_with_enumerations
            if enumeration_association?
              klass = @record.class.reflections[name.to_sym].klass
              type = klass.columns_hash[klass.enumerator_attribute.to_s].type
              
              case type
                when :text
                  :string
                when :time
                  :datetime
                else
                  type
              end
            else
              compute_type_without_enumerations
            end
          end
          
          # Gets the real value representing the enumerator
          def compute_value_with_enumerations
            if enumeration_association?
              association = @record.send(name)
              association.enumerator if association
            else
              compute_value_without_enumerations
            end
          end
          
          # Is this attribute defined by an enumeration association?
          def enumeration_association?
            @enumeration_association ||= @record.enumeration_associations.value?(name)
          end
      end
    end
  end
end

ActiveRecord::XmlSerializer::Attribute.class_eval do
  include EnumerateBy::Extensions::XmlSerializer::Attribute
end
