require 'acts_as_enumeration/extensions/associations'
require 'acts_as_enumeration/extensions/base_conditions'

module PluginAWeek #:nodoc:
  module Acts #:nodoc:
    module Enumeration #:nodoc:
      def self.included(base) #:nodoc:
        base.extend(MacroMethods)
      end
      
      module MacroMethods
        # 
        def acts_as_enumeration
          validates_uniqueness_of :name
          
          before_save :reset_cache
          before_destroy :reset_cache
          
          extend PluginAWeek::Acts::Enumeration::ClassMethods
          include PluginAWeek::Acts::Enumeration::InstanceMethods
        end
        
        # Is this class an enumeration?
        def enumeration?
          extended_by.include?(PluginAWeek::Acts::Enumeration::ClassMethods)
        end
      end
      
      module ClassMethods
        # Finds all of the values in this enumeration.  The values will be cached
        # until the cache is reset either manually or automatically when the
        # model chanages
        def all
          @all ||= find(:all).map(&:freeze).freeze
        end
        
        # Looks up the corresponding record.  You can lookup the following types:
        # * symbol - The symbol name of the enum value
        # * string - The name of the enum value
        # * fixnum - The id of the record
        # 
        # Any other type will cause a TypeError exception to be raised.  If a
        # record cannot be found, then a RecordNotFound exception will be raised.
        # 
        # If you do not want to worry about exceptions, then use find_by_id or
        # find_by_name.
        def [](id)
          find_enum(id) || raise(ActiveRecord::RecordNotFound, "Couldn't find #{name} for #{id}")
        end
        
        # Determines whether this enumeration includes the given id
        def includes?(id)
          !find_enum(id).nil?
        end
        
        # Resets the colletion of values in the enumeration
        def reset_cache
          @all = @all_by_name = @all_by_id = nil
        end
        
        # Finds the enumerated value with the given id
        def find_by_id(id)
          @all_by_id ||= all.inject({}) {|memo, item| memo[item.id] = item; memo;}.freeze
          @all_by_id[id]
        end
        
        # Finds the enumerated value with the given name
        def find_by_name(name)
          @all_by_name ||= all.inject({}) {|memo, item| memo[item.name] = item; memo;}.freeze
          @all_by_name[name.is_a?(Symbol) ? name.id2name : name]
        end
        
        private
          def find_enum(id)
            case id
              when Symbol
                value = find_by_name(id.id2name)
              when String
                value = find_by_name(id)
              when Fixnum
                value = find_by_id(id)
              when nil
                value = nil
              else
                raise TypeError, "#{self.name}[]: id should be a String, Symbol or Fixnum but got a: #{id.class.name}"
            end
            
            value
          end
      end
      
      module InstanceMethods
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
        
        # Returns the symbol value of the name
        def to_sym
          self.name.to_sym
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include PluginAWeek::Acts::Enumeration
end