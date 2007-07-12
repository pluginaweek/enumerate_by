module PluginAWeek #:nodoc:
  module Acts #:nodoc:
    module Enumeration #:nodoc:
      module Extensions #:nodoc:
        module Associations #:nodoc:
          def self.extended(base) #:nodoc:
            class << base
              alias_method_chain :belongs_to, :enumerations
            end
          end
          
          # 
          def belongs_to_with_enumerations(association_id, options)
            if enumerated = options.delete(:enumerated)
              options.assert_valid_keys(
                :class_name,
                :foreign_key
              )
              
              belongs_to_without_enumerations(association_id, options)
              reflection = reflections[association_id.to_sym]
              
              name = reflection.name
              primary_key_name = reflection.primary_key_name
              class_name = reflection.class_name
              
              module_eval <<-end_eval
                def #{name}
                  #{class_name}.find_by_id(self.#{primary_key_name})
                end
                
                def #{name}_with_enumerations=(new_value)
                  self.#{name}_without_enumerations = #{class_name} === new_value ? new_value : #{class_name}[new_value]
                end
                alias_method_chain :#{name}=, :enumerations
              end_eval
            else
              belongs_to_without_enumerations(association_id, options)
            end
          end
        end
      end
    end
  end
end