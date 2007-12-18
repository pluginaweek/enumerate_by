require 'has_finder'
require 'acts_as_enumeration/extensions/associations'
require 'acts_as_enumeration/extensions/base_conditions'

module PluginAWeek #:nodoc:
  module Acts #:nodoc:
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
    module Enumeration
      def self.included(base) #:nodoc:
        base.extend(MacroMethods)
      end
      
      module MacroMethods
        # Indicates that this class is a representative of an enumeration.
        def acts_as_enumeration
          after_save :reset_cache
          after_destroy :reset_cache
          
          extend PluginAWeek::Acts::Enumeration::ClassMethods
          include PluginAWeek::Acts::Enumeration::InstanceMethods
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
            column :name, :string
            
            class_inheritable_array :columns
            class_inheritable_array :identifiers
            
            validates_presence_of :name
          end
        end
        
        # Defines a new column in the model
        def column(name, sql_type = nil, default = nil, null = true)
          write_inheritable_array(:columns, [ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)])
        end
        
        # Finds all of the values in this enumeration.  The values will be cached
        # until the cache is reset either manually or automatically when the
        # model chanages.
        def find_every(options)
          @all ||= (identifiers || []).dup.freeze
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
        # * +symbol+ - The symbol name of the enum value
        # * +string+ - The name of the enum value
        # * +fixnum+ - The id of the record
        # 
        # Any other type will cause a TypeError exception to be raised.  If a
        # record cannot be found, then a RecordNotFound exception will be raised.
        # 
        # If you do not want to worry about exceptions, then use +find_by_id+ or
        # +find_by_name+.
        def [](id)
          find_by_any(id) || raise(ActiveRecord::RecordNotFound, "Couldn't find #{name} with id #{id.inspect}")
        end
        
        # Determines whether this enumeration includes the given id
        def includes?(id)
          !find_by_any(id).nil?
        end
        
        # Finds the enumerated value with the given id
        def find_by_id(id)
          @all_by_id ||= find(:all).inject({}) {|items, item| items[item.id] = item; items;}
          @all_by_id[id]
        end
        
        # Finds the enumerated value with the given name
        def find_by_name(name)
          @all_by_name ||= find(:all).inject({}) do |items, item|
            items[item.name] = item
            
            # Add the item's safe name in case it contains characters that aren't
            # easily used in symbols
            safe_name = item.name.gsub(/[^A-Za-z0-9-]/, '').underscore
            items[safe_name] = item if safe_name != item.name
            
            items
          end
          
          @all_by_name[name.is_a?(Symbol) ? name.id2name : name]
        end
        
        # Finds the enumerated value indicated by id or returns nil if nothing
        # was found
        def find_by_any(id)
          case id
          when Symbol
            find_by_name(id.id2name)
          when String
            find_by_name(id)
          when Fixnum
            find_by_id(id)
          when nil
            nil
          else
            raise TypeError, "#{name}: id should be a String, Symbol or Fixnum but got a: #{id.class.name}"
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
        
        # Resets the colletion of values in the enumeration
        def reset_cache
          @all = @all_by_name = @all_by_id = nil
        end
      end
      
      module InstanceMethods
        def create_without_callbacks #:nodoc:
          self.class.write_inheritable_array(:identifiers, [self])
          @new_record = false
          readonly!
          self.id
        end
        
        def destroy_without_callbacks #:nodoc:
          self.class.identifiers.delete(self)
          freeze
        end
        
        def validate #:nodoc:
          if name && existing = self.class.find_by_name(name)
            errors.add :name, 'has already been taken' if existing != self
          end
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
        
        # Check whether the method is the name of an identifier in this
        # enumeration
        def method_missing(method_id, *arguments)
          if match = /^(\w*)\?$/.match(method_id.to_s)
            if identifier = self.class.find_by_name(match[1])
              self == identifier
            else
              super
            end
          else
            super
          end
        end
        
        # Whether or not this enumeration is equal to the given value
        def ===(arg)
          case arg
          when Symbol, String, Fixnum, nil
            return self == self.class[arg]
          when Array
            return in?(*arg)
          end
          
          super
        end
        
        # Determines whether this enumeration is in the given list
        def in?(*list)
          list.any? {|item| self === item}
        end
        
        # Returns the symbolic value of the name
        def to_sym
          name.to_sym
        end
        
        # Returns the value of the name
        def to_s
          name
        end
        
        private
          def reset_cache
            self.class.reset_cache
          end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include PluginAWeek::Acts::Enumeration
end
