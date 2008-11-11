require 'acts_as_enumeration/collection'
require 'acts_as_enumeration/extensions/associations'
require 'acts_as_enumeration/extensions/base_conditions'
require 'acts_as_enumeration/extensions/serializer'
require 'acts_as_enumeration/extensions/xml_serializer'

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
  # type of enumeration, but it should be sufficient with support for queries
  # by attribute, e.g. Color.find_by_name('red')
  # 
  # == Accessing enumeration identifiers
  # 
  # The actual records for an enumeration identifier can be accessed by id or
  # name:
  # 
  #   Color[1]      # => #<Color id: 1, name: "red">
  #   Color['red']  # => #<Color id: 1, name: "red">
  # 
  # These records are cached, so there is no performance hit and the same object
  # can be compared against itself, i.e. Color[1] == Color['red']
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
  # the commonly used +name+ attribute.  This attribute will also determine what
  # values are indexed for the enumeration's lookup identifiers.  In this case,
  # records can be accessed by id or title:
  # 
  #   Book[1]        # => #<Book id: 1, title: "Blink">
  #   Book['Blink']  # => #<Book id: 1, title: "Blink">
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
  #     
  #     create :id => 1, :title => 'Blink', :author => 'Malcolm Gladwell', :num_pages => 277
  #   end
  # 
  # These attributes are exactly like normal ActiveRecord attributes:
  # 
  #   Book['Blink']   # => #<Book id: 1, title: "Blink", author: "Malcolm Gladwell", num_pages: 277>
  module ActsAsEnumeration
    module MacroMethods
      def self.extended(base) #:nodoc:
        base.class_eval do
          # Tracks which attributes represent enumerations
          class_inheritable_accessor :enumeration_associations
          self.enumeration_associations = {}
        end
      end
      
      # Indicates that this class should be representative of an enumeration.
      # 
      # The default attribute used to reference a unique identifier is +name+.
      # You can override this by specifying a custom attribute that will be
      # used to uniquely reference a particular identifier. See PluginAWeek::ActsAsEnumeration
      # for more information.
      # 
      # == Attributes
      # 
      # The following columns are automatically generated for the model:
      # * +id+ - The unique id for a recrod
      # * <tt>#{attribute}</tt> - The unique attribute specified
      # 
      # == Validations
      # 
      # In addition to the default columns, default validations are generated
      # to ensure the presence of the default attributes and that the
      # identifier attribute is unique across all records.
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
    
    # The various types of ActiveRecord finder options aren't all supported for
    # enumerations due to the fact that the objects are not backed by a data
    # store.  However, some of the default finders *do* work, including:
    # * <tt>find(:all)</tt>
    # * <tt>find(1)</tt>
    # * <tt>find(1, 2, 3)</tt>
    # 
    # In addition to these generic finders, there are also individual finders
    # for each column. See +column+ for more information about how those are
    # generated.
    # 
    # *Note* that additional finder options like <tt>:conditions</tt> and
    # <tt>:order</tt> are not supported in enumerations. As a result, you should
    # resort to using Ruby's Array/Enumerable interface.
    module ClassMethods
      def self.extended(base) #:nodoc:
        class << base
          # Don't allow silent failures
          alias_method :create, :create!
        end
      end
      
      # Defines a new column in the model.  The following defaults are defined:
      # * +sql_type+ - None; any value allowed
      # * +default+ - No default
      # * +null+ - Allow null values
      # 
      # == Finder methods
      # 
      # When a new column is defined, a finder method is generated for it.  For
      # example, if a column called +title+ is generated, then the following
      # finder methods are generated:
      # * <tt>find_all_by_title(value)</tt> - Finds all enumeration identifiers with the given title
      # * <tt>find_by_title(value)</tt> - Finds the first enumeration identifier with the given title
      # 
      # == Caching
      # 
      # The results from each finder called are cached. As a result, there should
      # be no performance hit when using them.
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
      def find_every(options) #:nodoc:
        @all ||= Collection.new(identifiers || [])
        @all.dup
      end
      
      # Finds the identifier with the given id
      def find_one(id, options) #:nodoc:
        if result = find_by_id(id)
          result
        else
          raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with ID=#{id}"
        end
      end
      
      # Finds the identifiers with the given ids
      def find_some(ids, options) #:nodoc:
        result = ids.map {|id| find_by_id(id)}.compact
        if result.size == ids.size
          Collection.new(result)
        else
          raise ActiveRecord::RecordNotFound, "Couldn't find all #{name.pluralize} with IDs (#{ids.join(',')})"
        end
      end
      
      # Looks up the corresponding enumeration record.  You can lookup the
      # following types:
      # * +fixnum+ - The id of the record
      # * +string+ - The value of the identifier attribute
      # * +symbol+ - The symbolic value of the identifier attribute
      # 
      # If you do not want to worry about exceptions, then use +find_by_id+ or
      # +<tt>find_by_#{attribute}</tt>, where attribute is the identifier attribute
      # specified when calling +acts_as_enumeration+.
      # 
      # == Examples
      # 
      #   class Book < ActiveRecord::Base
      #     acts_as_enumeration :title
      #     
      #     create :id => 1, :title => 'Blink'
      #   end
      # 
      #   Book[1]         # => #<Book id: 1, title: "Blink">
      #   Book['Blink']   # => #<Book id: 1, title: "Blink">
      #   Book[:Blink]    # => #<Book id: 1, title: "Blink">
      #   Book[2]         # => ActiveRecord::RecordNotFound: Couldn't find Book with value(s) 2
      #   Book['Invalid'] # => ActiveRecord::RecordNotFound: Couldn't find Book with value(s) "Invalid"
      def [](value)
        find_by_any(value) || raise(ActiveRecord::RecordNotFound, "Couldn't find #{name} with value #{value.inspect}")
      end
      
      # Finds all records that have an attribute with the given value. This is
      # the generic finder used by each attribute finder.  For example,
      # 
      #   find_all_by_attribute(:title, 'Blink')
      #   find_all_by_attribute(:id, 1)
      def find_all_by_attribute(attribute, value)
        attribute = attribute.to_s
        value = value.to_s if value.is_a?(Symbol) && attribute == enumeration_attribute
        
        if records = @all_by[attribute][value]
          records.dup
        else
          []
        end
      end
      
      # Finds the first record the has an attribute with the given value. This is
      # the generic finder used by each attribute finder.  For example,
      # 
      #   find_by_attribute(:title, 'Blink')
      #   find_by_attribute(:id, 1)
      def find_by_attribute(attribute, value)
        find_all_by_attribute(attribute, value).first
      end
      
      # Finds the record that matches the enumeration's identifer attribute for
      # the given value. The attribute is based on what was specified when calling
      # +acts_as_enumeration+.
      def find_by_enumeration_attribute(value)
        send("find_by_#{enumeration_attribute}", value)
      end
      
      # Finds the enumerated value indicated by the given value or returns nil
      # if nothing was found. The value can be any one of the following types:
      # * +fixnum+ - The id of the record
      # * +string+ - The value of the identifier attribute
      # * +symbol+ - The symbolic value of the identifier attribute
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
      
      # Is this class an enumeration?  This value is used to determine when
      # +belongs_to+, +has_one+, and +has_many+ associations should using the
      # enumeration interface instead of going through ActiveRecord.
      def enumeration?
        true
      end
      
      # Updates the cache based on the operation being performed. We prefer to
      # update the cache rather than reset for performance reasons.  The valid
      # types of operations are:
      # * +push+ - Adds the record to the cache
      # * +delete+ - Deletes the record from the cache
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
            @all_by[column.name][value] = Collection.new([record])
          end
        end
      end
    end
    
    # Many of the ActiveRecord features are removed from enumerations to improve
    # performance for enumerations with a large number of values (e.g. countries
    # or regions).  These features include:
    # * Dirty tracking - Tracks when attribute values have changed for a record
    # * Callbacks - Allows other code to hook into the save/update/destroy/etc. process
    # 
    # These features do not provide any particular benefit for runtime usage when
    # used with enumerations, since enumerations should not be dynamic during
    # the runtime.
    # 
    # == Equality
    # 
    # It's important to note that there *is* support for performing equality
    # comparisons with other objects based on the value of the enumeration's
    # identifier attribute specified when calling +acts_as_enumeration+.  This
    # is useful for case statements or when used within view helpers like
    # +collection_select+
    # 
    # For example,
    # 
    #   class Book < ActiveRecord::Base
    #     acts_as_enumeration :title
    #     
    #     create :id => 1, :title => 'Blink'
    #   end
    # 
    #   Book[1] == 1              # => true
    #   1 == Book[1]              # => true
    #   Book['Blink'] == 'Blink'  # => true
    #   'Blink' == Book['Blink']  # => true
    #   Book['Blink'] == Blink[1] # => true
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
      
      # Enumeration values should never really be destroyed during runtime.
      # However, this is supported to complete the full circle for an record's
      # liftime in ActiveRecord
      def destroy #:nodoc:
        self.class.identifiers.delete(self)
        remove_from_cache
        freeze
      end
      
      # Clears the various record caches, but doesn't actually try to reload
      # any values from the database
      def reload(options = nil) #:nodoc:
        clear_aggregation_cache
        clear_association_cache
        self
      end
      
      # Whether or not this enumeration is equal to the given value. Equality
      # is based on the following types:
      # * +fixnum+ - The id of the record
      # * +string+ - The value of the identifier attribute
      # * +symbol+ - The symbolic value of the identifier attribute
      def ==(arg)
        case arg
        when String, Fixnum, Symbol
          self == self.class[arg]
        else
          super
        end
      end
      
      # Determines whether this enumeration is in the given list
      def in?(*list)
        list.any? {|item| self === item}
      end
      
      # The current value for the enumeration attribute
      def enumeration_value
        send("#{enumeration_attribute}")
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
  extend PluginAWeek::ActsAsEnumeration::MacroMethods
end
