module PluginAWeek #:nodoc:
  module Acts #:nodoc:
    module Enumeration
      module Extensions #:nodoc:
        # Adds auto-generated methods for any belongs_to enumeration
        # associations.  For example,
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
        # will auto-generate the +find+ and +count+ class methods for each
        # Color identifier in the Car class like so:
        # 
        #   red_cars = Car.red.find(:all)
        #   blue_car = Car.blue.find(:first)
        #   green_cars = Car.green.find(:all)
        #   
        #   number_of_red_cars = Car.red.count
        #   number_of_blue_cars = Car.blue.count
        #   number_of_green_cars = Car.green.count(:limit => 10)
        module Associations
          def self.extended(base) #:nodoc:
            class << base
              alias_method_chain :belongs_to, :enumerations
            end
          end
          
          # Override default accessor methods so that, for enumerations, the
          # reader method only accesses the cache and the write method can
          # understand assigning strings, symbols, or numbers to the association
          def belongs_to_with_enumerations(association_id, options = {})
            belongs_to_without_enumerations(association_id, options)
            reflection = reflections[association_id.to_sym]
            
            if !reflection.options[:polymorphic] && reflection.klass.enumeration?
              name = reflection.name
              primary_key_name = reflection.primary_key_name
              class_name = reflection.class_name
              klass = reflection.klass
              
              klass.find(:all).each do |identifier|
                has_finder identifier.to_sym, :conditions => {primary_key_name.to_sym => identifier.id}
              end
              
              module_eval <<-end_eval
                def #{name}
                  #{class_name}.find_by_id(self.#{primary_key_name})
                end
                
                def #{name}_with_enumerations=(new_value)
                  self.#{name}_without_enumerations = new_value.is_a?(#{class_name}) ? new_value : #{class_name}.find_by_any(new_value)
                end
                alias_method_chain :#{name}=, :enumerations
              end_eval
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  extend PluginAWeek::Acts::Enumeration::Extensions::Associations
end
