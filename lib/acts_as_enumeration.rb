require 'acts_as_enumeration/extensions/associations'
require 'acts_as_enumeration/extensions/base_conditions'

module PluginAWeek #:nodoc:
  # An enumeration defines a finite set of identifiers which (often) have no
  # numerical order.  This plugin provides a general technique for using
  # ActiveRecord classes to define enumerations.
  # 
  # == Defining enumerations
  # 
  # To define a model as an enumeration:
  # 
  #   class Color < ActiveRecord::Base
  #     acts_as_enumeration
  #   end
  # 
  # This will create the class/instance methods for accessing the enumeration
  # identifiers.
  # 
  # == Defining identifiers
  # 
  # Identifiers represent the individual values within the enumeration.
  # Enumerations +do not+ have a database backing.  Instead, the records are
  # all created and maintained within the enumeration class.  For example,
  # 
  #   class Color < ActiveRecord::Base
  #     acts_as_enumeration
  #     
  #     create :id => 1, :name => 'red'
  #     create :id => 2, :name => 'blue'
  #     create :id => 3, :name => 'green'
  #   end
  # 
  # There are certain restrictions on what types of queries can be run on this
  # type of enumeration, but it should be sufficient.
  # 
  # == Accessing enumeration identifiers
  # 
  # The actual records for an enumeration identifier can be accessed by id or
  # name:
  # 
  #   >> Color[:red]
  #   => #<Color:0x480c808 @attributes={"name"=>"red", "id"=>"1"}>
  #   >> Color[1]
  #   => #<Color:0x480c808 @attributes={"name"=>"red", "id"=>"1"}>
  # 
  # == Custom-identified enumerations
  # 
  # Sometimes you may need to create enumerations that are based on an attribute
  # other than +name+.  For example,
  # 
  #   class Book
  #     acts_as_enumeration :title
  #     
  #     create :id => 1, :title => 'Blink'
  #   end
  # 
  # This will create enumerations identified by the +title+ attribute instead of
  # the commonly used +name+ attribute.
  # 
  # == Multi-dimensional identified enumerations
  # 
  # You may also need to define enumerations that are uniquely identified by
  # multiple attributes.  For example,
  # 
  #   class AccessPath
  #     acts_as_enumeration :controller, :action
  #     
  #     create :id => 1, :controller => 'users', :action => 'index'identifier
  #     create :id => 2, :controller => 'users', :action => 'new'
  #     create :id => 3, :controller => 'sessions', :action => 'new'
  #   end
  #  
  # These types of enumerations define identifiers that are unique on two dimensions:
  # +controller+ + +action+.  Access to the individual identifies is similar to
  # accessing one-dimensional enumerations:
  # 
  #   >> AccessPath[:users, :index]
  #   => #<AccessPath:0x480c808 @attributes={"controller"=>"users", "action"=>"index", "id"=>"1"}>
  #   >> AccessPath[:users, :new]
  #   =>  #<AccessPath:0x480c908 @attributes={"controller"=>"users", "action=>"new", "id"=>"2"}>
  module ActsAsEnumeration #:nodoc:
    def self.included(base) #:nodoc:
      base.class_eval do
        extend PluginAWeek::ActsAsEnumeration::MacroMethods
      end
    end
    
    module MacroMethods
      # Indicates that this class is a representative of an enumeration.
      # 
      # The default attribute used to reference a unique identifier is +name+.
      # You can override this by specifying one or more attributes that will be
      # used to uniquely reference a particular identifier. See PluginAWeek::ActsAsEnumeration
      # for more information about single- vs. multi-dimensional enumerations.
      def acts_as_enumeration(*attributes)
        attributes << :name if attributes.empty?
        attributes.map!(&:to_s)
        
        write_inheritable_attribute :enumeration_attributes, attributes
        class_inheritable_reader :enumeration_attributes
        
        after_save :add_to_cache
        after_destroy :remove_from_cache
        
        extend PluginAWeek::ActsAsEnumeration::ClassMethods
        include PluginAWeek::ActsAsEnumeration::InstanceMethods
        
        # Override association accessors for any models that have defined an
        # association with this enumeration
        ActiveRecord::Base.send(:subclasses).each do |model|
          model.reflections.each do |association_id, reflection|
            if [:has_many, :has_one].include?(reflection.macro) && reflection.class_name == self.to_s
              model.send("#{reflection.macro}_enumeration_accessor_methods", reflection)
            end
          end
        end
      end
      
      # Is this class an enumeration?
      def enumeration?
        false
      end
    end
    
    module ClassMethods
      def self.extended(base) #:nodoc:
        base.class_eval do
          column :id, :integer
          
          enumeration_attributes.each do |attribute|
            column attribute, :string
          end
          
          class_inheritable_array :columns
          class_inheritable_array :identifiers
          
          validates_presence_of :id
          validates_presence_of enumeration_attributes.first if enumeration_attributes.length == 1
          validate :identifier_is_unique
        end
      end
      
      # Defines a new column in the model
      def column(name, sql_type = nil, default = nil, null = true)
        write_inheritable_array(:columns, [ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)])
        
        # Add finders
        class_eval <<-end_eval
          def self.find_all_by_#{name}(value)
            find_all_by_attribute("#{name}", value)
          end
          
          def self.find_by_#{name}(value)
            find_by_attribute("#{name}", value)
          end
        end_eval
      end
      
      # Finds all of the values in this enumeration.  The values will be cached
      # until the cache is reset either manually or automatically when the
      # model chanages.
      def find_every(options)
        @all ||= (identifiers || []).dup
        @all.dup
      end
      
      # Finds the identifier with the given id
      def find_one(id, options)
        if result = find_by_id(id)
          result
        else
          raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with ID=#{id}"
        end
      end
      
      # Finds the identifiers with the given ids
      def find_some(ids, options)
        result = ids.map {|id| find_by_id(id)}.compact
        if result.size == ids.size
          result
        else
          raise ActiveRecord::RecordNotFound, "Couldn't find all #{name.pluralize} with IDs (#{ids.join(',')})"
        end
      end
      
      # Looks up the corresponding record.  You can lookup the following types:
      # * +fixnum+ - The id of the record
      # * +symbol+ - The symbolic name of the identifier
      # * +string+ - The name of the identifier
      # * +Array+ - An array of strings/symbols that reference the identifier
      # 
      # If you do not want to worry about exceptions, then use +find_by_id+ or
      # +find_by_name+.
      def [](*values)
        find_by_any(*values) || raise(ActiveRecord::RecordNotFound, "Couldn't find #{name} with value(s) #{values.length == 1 ? values.first.inspect : values.inspect}")
      end
      
      # Finds all records that have an attribute with the given record
      def find_all_by_attribute(attribute, value)
        attribute = attribute.to_s
        value = value.to_s if value.is_a?(Symbol) && enumeration_attributes.include?(attribute)
        
        @all_by ||= {}
        @all_by[attribute] ||= {}
        @all_by[attribute][value] ||= find(:all).inject([]) {|items, item| items << item if item.send(attribute) == value; items}
        @all_by[attribute][value].dup
      end
      
      # Finds the first record the has an attribute with the given value
      def find_by_attribute(attribute, value)
        find_all_by_attribute(attribute, value).first
      end
      
      # Finds the record that matches all of the model's enumeration attributes for
      # the given values
      def find_by_enumeration_attributes(*values)
        values = values.flatten.map {|value| value && (value.is_a?(Symbol) ? value.to_s : value)}
        
        @all_by_enumeration_attributes ||= {}
        unless record = @all_by_enumeration_attributes[values]
          records = find_all_by_attribute(enumeration_attributes.first, values.first)
          values[1..-1].each_with_index do |value, index|
            records &= find_all_by_attribute(enumeration_attributes[index + 1], value)
          end
          
          @all_by_enumeration_attributes[values] = record = records.first
        end
        
        record
      end
      
      # Finds the enumerated value indicated by id or returns nil if nothing
      # was found
      def find_by_any(*values)
        if values.length == 1 && values.first.is_a?(Fixnum)
          find_by_id(values.first)
        else
          find_by_enumeration_attributes(*values)
        end
      end
      
      # Counts the number of enumerated values defined
      def count(*args)
        find(:all).size
      end
      
      # Is this class an enumeration?
      def enumeration?
        true
      end
      
      # Updates the cache based on the operation being performed. We prefer to
      # update the cache rather than reset for performance reasons.
      def update_cache(operation, record)
        # Remove from all cache
        @all.send(operation, record) if @all
        
        # Remove from all_by cache
        @all_by.each do |attribute, values|
          if records = values[record.send(attribute)]
            records.send(operation, record)
          end
        end if @all_by
        
        # Remove from enumeration value cache
        enumeration_values = record.enumeration_values
        (0..enumeration_values.length - 1).each do |index|
          values = enumeration_values[0..index]
          if operation == :delete
            @all_by_enumeration_attributes.delete(values) if @all_by_enumeration_attributes[values] == record
          else
            @all_by_enumeration_attributes[values] ||= record
          end
        end if @all_by_enumeration_attributes
      end
      
      # Resets the collection of values in the enumeration
      def reset_cache
        @all = @all_by = @all_by_enumeration_attributes = nil
      end
    end
    
    module InstanceMethods
      def create_without_callbacks #:nodoc:
        self.class.write_inheritable_array(:identifiers, [self])
        @new_record = false
        readonly!
        id
      end
      
      def destroy_without_callbacks #:nodoc:
        self.class.identifiers.delete(self)
        freeze
      end
      
      def reload(options = nil) #:nodoc:
        clear_aggregation_cache
        clear_association_cache
        self
      end
      
      # Allow id to be assigned via ActiveRecord::Base#attributes=
      def attributes_protected_by_default #:nodoc:
        []
      end
      
      # Whether or not this enumeration is equal to the given value
      def ==(arg)
        case arg
        when Symbol, String, Fixnum
          return self == self.class.find_by_any(arg)
        else
          super
        end
      end
      
      # Determines whether this enumeration is in the given list
      def in?(*list)
        list.any? {|item| self === item}
      end
      
      # Gets the values matching the enumeration attributes
      def enumeration_values
        enumeration_attributes.collect {|attribute| send(attribute)}.map {|value| value && (value.is_a?(Symbol) ? value.to_s : value)}
      end
      
      # Stringifies the enumeration attributes
      def to_s
        enumeration_values * ', '
      end
      
      private
        # Does this identifier have unique enumeration values?
        def identifier_is_unique
          existing_record = self.class.find_by_enumeration_attributes(enumeration_values)
          errors.add(enumeration_attributes.first, ActiveRecord::Errors.default_error_messages[:taken]) if existing_record && existing_record != self
        end
        
        # Adds this record to the cache
        def add_to_cache
          self.class.update_cache(:push, self)
        end
        
        # Removes this record from the cache
        def remove_from_cache
          self.class.update_cache(:delete, self)
        end
    end
  end
end

ActiveRecord::Base.class_eval do
  include PluginAWeek::ActsAsEnumeration
end
