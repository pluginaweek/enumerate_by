module PluginAWeek #:nodoc:
  module ActsAsEnumeration
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
      # will auto-generate named scopes for the Color enumeration like so:
      # 
      #   red_cars = Car.with_color(:red)
      #   blue_car = Car.with_color(:blue)
      #   red_and_blue_cars = Car.with_colors(:red, :blue)
      module Associations
        def self.extended(base) #:nodoc:
          class << base
            alias_method_chain :has_many, :enumerations
            alias_method_chain :has_one, :enumerations
            alias_method_chain :belongs_to, :enumerations
          end
        end
        
        # Adds support for has_many and enumerations
        def has_many_with_enumerations(association_id, options = {}, &extension)
          has_many_without_enumerations(association_id, options, &extension)
          
          reflection = reflections[association_id.to_sym]
          name = reflection.name
          
          define_method("#{name}_with_enumerations") do
            klass = reflection.klass
            
            # If we're looking up an enumeration class, then use its finder
            if klass.enumeration?
              klass.send("find_all_by_#{reflection.primary_key_name}", send(self.class.primary_key))
            else
              value = send("#{name}_without_enumerations")
              instance_variable_set("@#{name}", nil) if self.class.enumeration? # Get rid of the cached value
              value
            end
          end
          alias_method_chain name, :enumerations
        end
        
        # Adds support for has_one and enumerations
        def has_one_with_enumerations(association_id, options = {})
          has_one_without_enumerations(association_id, options)
          
          reflection = reflections[association_id.to_sym]
          name = reflection.name
          
          define_method("#{name}_with_enumerations") do
            klass = reflection.klass
            
            # If we're looking up an enumeration class, then use its finder
            if klass.enumeration?
              klass.send("find_by_#{reflection.primary_key_name}", send(self.class.primary_key))
            else
              value = send("#{name}_without_enumerations")
              instance_variable_set("@#{name}", nil) if self.class.enumeration? # Get rid of the cached value
              value
            end
          end
          alias_method_chain name, :enumerations
        end
        
        # Adds support for belongs_to and enumerations
        def belongs_to_with_enumerations(association_id, options = {})
          belongs_to_without_enumerations(association_id, options)
          
          # Override accessor if class is already defined
          reflection = reflections[association_id.to_sym]
          
          if !reflection.options[:polymorphic] && reflection.klass.enumeration?
            name = reflection.name
            primary_key_name = reflection.primary_key_name
            class_name = reflection.class_name
            klass = reflection.klass
            
            if enumeration?
              # Create our own named scope since we can't run queries on the enumeration class
              (class << self; self; end).instance_eval do
                define_method("with_#{name}") do |*identifiers|
                  identifiers.flatten!
                  values = klass.send("find_all_by_#{primary_key_name}", identifiers.shift)
                  identifiers.each do |identifier|
                    values &= klass.send("find_all_by_#{primary_key_name}", identifier)
                  end
                  
                  values
                end
                
                alias_method "with_#{name.to_s.pluralize}", "with_#{name}"
              end
            else
              # Add generic scopes that can have enumeration identifiers passed in
              %W(with_#{name} with_#{name.to_s.pluralize}).each do |scope_name|
                named_scope scope_name, Proc.new {|*identifiers| {
                  :conditions => {primary_key_name => identifiers.flatten.collect {|identifier| klass[identifier].id}}
                }}
              end
            end
            
            # Association reader
            define_method(name) do
              klass.find_by_id(send(primary_key_name))
            end
            
            # Association writer
            define_method("#{name}_with_enumerations=") do |new_value|
              send("#{name}_without_enumerations=", new_value.is_a?(klass) ? new_value : klass.find_by_any(new_value))
            end
            alias_method_chain "#{name}=", :enumerations
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  extend PluginAWeek::ActsAsEnumeration::Extensions::Associations
end
