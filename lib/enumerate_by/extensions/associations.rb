module EnumerateBy
  module Extensions #:nodoc:
    # Adds a set of helpers for using enumerations in associations, including
    # named scopes and assignment via enumerators.
    # 
    # The examples below assume the following models have been defined:
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
    # == Named scopes
    # 
    # A pair of named scopes are generated for each +belongs_to+ association
    # that is identified by an enumeration.  In this case, the following
    # named scopes get generated:
    # * +with_color+ / +with_colors+ - Finds all cars with the given color(s)
    # * +without_color+ / +without_colors+ - Finds all cars without the given color(s)
    # 
    # For example,
    # 
    #   Car.with_color('red')           # Cars with the color name "red"
    #   Car.without_color('red')        # Cars without the color name "red"
    #   Car.with_colors('red', 'blue')  # Cars with either the color names "red" or "blue"
    # 
    # == Association assignment
    # 
    # Normally, +belongs_to+ associations are assigned with either the actual
    # record or through its primary key.  When used with enumerations, support
    # is added for assigning these associations through the enumerators
    # defined for the class.
    # 
    # For example,
    # 
    #   # With valid enumerator
    #   car = Car.new         # => #<Car id: nil, color_id: nil>
    #   car.color = 'red'
    #   car.color_id          # => 1
    #   car.color             # => #<Color id: 1, name: "red">
    #   
    #   # With invalid enumerator
    #   car = Car.new         # => #<Car id: nil, color_id: nil>
    #   car.color = 'invalid'
    #   car.color_id          # => nil
    #   car.color             # => nil
    # 
    # In the above example, the actual Color association is automatically
    # looked up by finding the Color record identified by the enumerator the
    # given enumerator ("red" in this case).
    module Associations
      def self.extended(base) #:nodoc:
        class << base
          alias_method_chain :belongs_to, :enumerations
        end
      end
            
      # Adds support for belongs_to and enumerations
      def belongs_to_with_enumerations(association_id, options = {})
        belongs_to_without_enumerations(association_id, options)
        
        # Override accessor if class is valid enumeration
        reflection = reflections[association_id.to_sym]
        if !reflection.options[:polymorphic] && (reflection.klass < ActiveRecord::Base) && reflection.klass.enumeration?
          name = reflection.name
          primary_key_name = reflection.primary_key_name
          class_name = reflection.class_name
          klass = reflection.klass
          
          # Inclusion scopes
          %W(with_#{name} with_#{name.to_s.pluralize}).each do |scope_name|
            named_scope scope_name.to_sym, lambda {|*enumerators| {
              :conditions => {primary_key_name => enumerators.flatten.collect {|enumerator| klass[enumerator].id}}
            }}
          end
          
          # Exclusion scopes
          %W(without_#{name} without_#{name.to_s.pluralize}).each do |scope_name|
            named_scope scope_name.to_sym, lambda {|*enumerators| {
              :conditions => ["#{primary_key_name} NOT IN (?)", enumerators.flatten.collect {|enumerator| klass[enumerator].id}]
            }}
          end
          
          # Hook in shortcut writer
          define_method("#{name}_with_enumerators=") do |new_value|
            send("#{name}_without_enumerators=", new_value.is_a?(klass) ? new_value : klass.find_by_enumerator(new_value))
          end
          alias_method_chain "#{name}=", :enumerators
          
          # Track the association
          enumeration_associations[primary_key_name.to_s] = name.to_s
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  extend EnumerateBy::Extensions::Associations
end
