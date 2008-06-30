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
  #   >> Color['red']
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
  # == Additional enumeration attributes
  # 
  # In addition to the attribute used to identify an enumeration identifier, you
  # can also define additional attributes just like regular ActiveRecord models:
  # 
  #   class Book < ActiveRecord::Base
  #     acts_as_enumeration :title
  #     
  #     column :author, :string
  #     column :num_pages, :integer
  #     
  #     validates_presence_of :author
  #     validates_numericality_of :num_pages
  #   end
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
      # You can override this by specifying a custom attribute that will be
      # used to uniquely reference a particular identifier. See PluginAWeek::ActsAsEnumeration
      # for more information.
      def acts_as_enumeration(attribute = :name)
        write_inheritable_attribute :enumeration_attribute, attribute.to_s
        class_inheritable_reader :enumeration_attribute
        
        class_inheritable_array :columns
        class_inheritable_array :identifiers
        
        # Initialize the index cache
        @all_by = {}
        
        extend PluginAWeek::ActsAsEnumeration::ClassMethods
        include PluginAWeek::ActsAsEnumeration::InstanceMethods
        
        column :id, :integer
        column enumeration_attribute, :string
        
        validates_presence_of :id
        validates_presence_of enumeration_attribute
        validate :identifier_is_unique
      end
      
      # Is this class an enumeration?
      def enumeration?
        false
      end
    end
    
    module ClassMethods
      def self.extended(base) #:nodoc:
        class << base
          # Don't allow silent failures
          alias_method :create, :create!
        end
      end
      
      # Defines a new column in the model
      def column(name, sql_type = nil, default = nil, null = true)
        # Remove any existing columns with the same name
        columns.reject! {|column| column.name == name.to_s} if columns
        
        write_inheritable_array(:columns, [ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)])
        
        # Add finders
        klass = class << self; self; end
        klass.class_eval do
          define_method("find_all_by_#{name}") do |value|
            find_all_by_attribute(name, value)
          end
          
          define_method("find_by_#{name}") do |value|
            find_by_attribute(name, value)
          end
        end
        
        # Prepare index cache for this column
        @all_by[name.to_s] = {}
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
      # 
      # If you do not want to worry about exceptions, then use +find_by_id+ or
      # +<tt>find_by_#{attribute}</tt>.
      def [](value)
        find_by_any(value) || raise(ActiveRecord::RecordNotFound, "Couldn't find #{name} with value #{value.inspect}")
      end
      
      # Finds all records that have an attribute with the given record
      def find_all_by_attribute(attribute, value)
        attribute = attribute.to_s
        value = value.to_s if value.is_a?(Symbol) && attribute == enumeration_attribute
        
        if records = @all_by[attribute][value]
          records.dup
        else
          []
        end
      end
      
      # Finds the first record the has an attribute with the given value
      def find_by_attribute(attribute, value)
        find_all_by_attribute(attribute, value).first
      end
      
      # Finds the record that matches the model's enumeration attribute for the
      # given value
      def find_by_enumeration_attribute(value)
        send("find_by_#{enumeration_attribute}", value)
      end
      
      # Finds the enumerated value indicated by id or returns nil if nothing
      # was found
      def find_by_any(value)
        if value.is_a?(Fixnum)
          find_by_id(value)
        else
          find_by_enumeration_attribute(value)
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
        # Update the all cache
        @all.send(operation, record) if @all
        
        # Update the indexes for each attribute in the record to improve
        # performance when defining large enumerations
        columns.each do |column|
          value = record.send(column.name)
          
          if records = @all_by[column.name][value]
            records.send(operation, record)
          elsif operation == :push
            @all_by[column.name][value] = [record]
          end
        end
      end
    end
    
    module InstanceMethods
      def self.included(base) #:nodoc:
        base.class_eval do
          # Disable unused ActiveRecord features
          {:callbacks => %w(create_or_update valid?), :dirty => %w(write_attribute save save!)}.each do |feature, methods|
            methods.each do |method|
              method, punctuation = method.sub(/([?!=])$/, ''), $1
              alias_method "#{method}#{punctuation}", "#{method}_without_#{feature}#{punctuation}"
            end
          end
        end
      end
      
      def destroy #:nodoc:
        self.class.identifiers.delete(self)
        remove_from_cache
        freeze
      end
      
      def reload(options = nil) #:nodoc:
        clear_aggregation_cache
        clear_association_cache
        self
      end
      
      # Whether or not this enumeration is equal to the given value
      def ==(arg)
        case arg
        when Symbol, String, Fixnum
          self == self.class.find_by_any(arg)
        else
          super
        end
      end
      
      # Determines whether this enumeration is in the given list
      def in?(*list)
        list.any? {|item| self === item}
      end
      
      # Stringifies the enumeration attributes
      def to_s
        to_str
      end
      
      # Add support for equality comparison with strings
      def to_str
        enumeration_value
      end
      
      private
        def create #:nodoc:
          self.class.write_inheritable_array(:identifiers, [self])
          @new_record = false
          readonly!
          add_to_cache
          id
        end
        
        # The current value for the enumeration attribute
        def enumeration_value
          send("#{enumeration_attribute}")
        end
        
        # Allow id to be assigned via ActiveRecord::Base#attributes=
        def attributes_protected_by_default #:nodoc:
          []
        end
        
        # Does this identifier have a unique enumeration value?
        def identifier_is_unique
          existing_record = self.class.find_by_enumeration_attribute(enumeration_value)
          errors.add(enumeration_attribute, ActiveRecord::Errors.default_error_messages[:taken]) if existing_record && existing_record != self
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
