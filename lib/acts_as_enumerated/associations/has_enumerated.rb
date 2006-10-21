module PluginAWeek #:nodoc:
  module Aggregations #:nodoc:
    module HasEnumerated #:nodoc:
      def self.included(base) #:nodoc:
        base.extend(MacroMethods)
      end
      
      module MacroMethods
        #
        #
        def has_enumerated(association_id, options = {})
          options.assert_valid_keys(
            :class_name,
            :foreign_key,
            :on_lookup_failure
          )
          failure_handler = options.delete(:on_lookup_failure)
          
          belongs_to(association_id, options)
          reflection = reflections[association_id.to_sym]
          
          name = reflection.name
          foreign_key = reflection.primary_key_name
          class_name = reflection.class_name
          
          module_eval <<-end_eval
            def #{name}
              value = #{class_name}.lookup_id(self.#{foreign_key})
              
              if value.nil? && #{!failure_handler.nil?}
                return self.send(#{failure_handler.inspect}, :read, #{name.inspect}, #{foreign_key.inspect}, #{class_name.inspect}, self.#{foreign_key})
              end
              
              return value
            end         
            
            def #{name}=(arg)                         
              self.#{foreign_key} = #{class_name}[#{class_name} === arg ? arg.id : arg].id
            end
          end_eval
        end
      end
    end
  end
end