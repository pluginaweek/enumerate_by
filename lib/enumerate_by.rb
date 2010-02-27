require 'enumerate_by/extensions/associations'
require 'enumerate_by/extensions/base_conditions'
require 'enumerate_by/extensions/serializer'
require 'enumerate_by/extensions/xml_serializer'

# An enumeration defines a finite set of enumerators which (often) have no
# numerical order.  This extension provides a general technique for using
# ActiveRecord classes to define enumerations.
module EnumerateBy
  # Whether to enable enumeration caching (default is true)
  mattr_accessor :perform_caching
  self.perform_caching = true
  
  module MacroMethods
    def self.extended(base) #:nodoc:
      base.class_eval do
        # Tracks which associations are backed by an enumeration
        # {"foreign key" => "association name"}
        class_inheritable_accessor :enumeration_associations
        self.enumeration_associations = {}
      end
    end
    
    # Indicates that this class is an enumeration.
    # 
    # The default attribute used to enumerate the class is +name+.  You can
    # override this by specifying a custom attribute that will be used to
    # *uniquely* reference a record.
    # 
    # *Note* that a presence and uniqueness validation is automatically
    # defined for the given attribute since all records must have this value
    # in order to be properly enumerated.
    # 
    # Configuration options:
    # * <tt>:cache</tt> - Whether to cache all finder queries for this
    #   enumeration.  Default is true.
    # 
    # == Defining enumerators
    # 
    # The enumerators of the class uniquely identify each record in the
    # table.  The enumerator value is based on the attribute described above.
    # In scenarios where the records are managed in code (like colors,
    # countries, states, etc.), records can be automatically synchronized
    # via #bootstrap.
    # 
    # == Accessing records
    # 
    # The actual records for an enumeration can be accessed via shortcut
    # helpers like so:
    # 
    #   Color['red']    # => #<Color id: 1, name: "red">
    #   Color['green']  # => #<Color id: 2, name: "green">
    # 
    # When caching is enabled, these lookup queries are cached so that there
    # is no performance hit.
    # 
    # == Associations
    # 
    # When using enumerations together with +belongs_to+ associations, the
    # enumerator value can be used as a shortcut for assigning the association.
    # 
    # In addition, the enumerator value is automatically used during
    # serialization (xml and json) of the associated record instead of the
    # foreign key for the association.
    # 
    # For more information about how to use enumerations with associations,
    # see EnumerateBy::Extensions::Associations and EnumerateBy::Extensions::Serializer.
    # 
    # === Finders
    # 
    # In order to be consistent by always using enumerators to reference
    # records, a set of finder extensions are added to allow searching
    # for records like so:
    # 
    #   class Car < ActiveRecord::Base
    #     belongs_to :color
    #   end
    #   
    #   Car.find_by_color('red')
    #   Car.all(:conditions => {:color => 'red'})
    # 
    # For more information about finders, see EnumerateBy::Extensions::BaseConditions.
    def enumerate_by(attribute = :name, options = {})
      options.reverse_merge!(:cache => true)
      options.assert_valid_keys(:cache)
      
      extend EnumerateBy::ClassMethods
      extend EnumerateBy::Bootstrapped
      include EnumerateBy::InstanceMethods
      
      # The attribute representing a record's enumerator
      cattr_accessor :enumerator_attribute
      self.enumerator_attribute = attribute
      
      # Whether to perform caching of enumerators within finder queries
      cattr_accessor :perform_enumerator_caching
      self.perform_enumerator_caching = options[:cache]
      
      # The cache store to use for queries (default is a memory store)
      cattr_accessor :enumerator_cache_store
      self.enumerator_cache_store = ActiveSupport::Cache::MemoryStore.new
      
      validates_presence_of attribute
      validates_uniqueness_of attribute
    end
    
    # Does this class define an enumeration?  Always false.
    def enumeration?
      false
    end
  end
  
  module ClassMethods
    # Does this class define an enumeration?  Always true.
    def enumeration?
      true
    end
    
    # Finds the record that is associated with the given enumerator.  The
    # attribute that defines the enumerator is based on what was specified
    # when calling +enumerate_by+.
    # 
    # For example,
    # 
    #   Color.find_by_enumerator('red')     # => #<Color id: 1, name: "red">
    #   Color.find_by_enumerator('invalid') # => nil
    def find_by_enumerator(enumerator)
      first(:conditions => {enumerator_attribute => typecast_enumerator(enumerator)})
    end
    
    # Finds the record that is associated with the given enumerator.  If no
    # record is found, then an ActiveRecord::RecordNotFound exception is
    # raised.
    # 
    # For example,
    # 
    #   Color['red']      # => #<Color id: 1, name: "red">
    #   Color['invalid']  # => ActiveRecord::RecordNotFound: Couldn't find Color with name "red"
    # 
    # To avoid raising an exception on invalid enumerators, use +find_by_enumerator+.
    def find_by_enumerator!(enumerator)
      find_by_enumerator(enumerator) || raise(ActiveRecord::RecordNotFound, "Couldn't find #{name} with #{enumerator_attribute} #{typecast_enumerator(enumerator).inspect}")
    end
    alias_method :[], :find_by_enumerator!
    
    # Finds records with the given enumerators.
    # 
    # For example,
    # 
    #   Color.find_all_by_enumerator(['red', 'green'])  # => [#<Color id: 1, name: "red">, #<Color id: 1, name: "green">]
    #   Color.find_all_by_enumerator('invalid')         # => []
    def find_all_by_enumerator(enumerators)
      all(:conditions => {enumerator_attribute => typecast_enumerator(enumerators)})
    end
    
    # Finds records with the given enumerators.  If no record is found for a
    # particular enumerator, then an ActiveRecord::RecordNotFound exception
    # is raised.
    # 
    # For Example,
    # 
    #   Color.find_all_by_enumerator!(['red', 'green']) # => [#<Color id: 1, name: "red">, #<Color id: 1, name: "green">]
    #   Color.find_all_by_enumerator!('invalid')        # => ActiveRecord::RecordNotFound: Couldn't find Color with name(s) "invalid"
    # 
    # To avoid raising an exception on invalid enumerators, use +find_all_by_enumerator+.
    def find_all_by_enumerator!(enumerators)
      enumerators = [enumerators].flatten
      records = find_all_by_enumerator(enumerators)
      missing = enumerators - records.map(&:enumerator)
      missing.empty? ? records : raise(ActiveRecord::RecordNotFound, "Couldn't find #{name} with #{enumerator_attribute}(s) #{missing.map(&:inspect).to_sentence}")
    end
    
    # Adds support for looking up results from the enumeration cache for
    # before querying the database.
    # 
    # This allows for enumerations to permanently cache find queries, avoiding
    # unnecessary lookups in the database.
    [:find_by_sql, :exists?, :calculate].each do |method|
      define_method(method) do |*args|
        if EnumerateBy.perform_caching && perform_enumerator_caching
          enumerator_cache_store.fetch([method] + args) { super(*args) }
        else
          super(*args)
        end
      end
    end
    
    # Temporarily disables the enumeration cache (as well as the query cache)
    # within the context of the given block if the enumeration is configured
    # to allow caching.
    def uncached
      old = perform_enumerator_caching
      self.perform_enumerator_caching = false
      super
    ensure
      self.perform_enumerator_caching = old
    end
    
    private
      # Typecasts the given enumerator to its actual value stored in the
      # database.  This will only convert symbols to strings.  All other values
      # will remain in the same type.
      def typecast_enumerator(enumerator)
        if enumerator.is_a?(Array)
          enumerator.flatten!
          enumerator.map! {|value| typecast_enumerator(value)}
          enumerator
        else
          enumerator.is_a?(Symbol) ? enumerator.to_s : enumerator
        end
      end
  end
  
  module Bootstrapped
    # Synchronizes the given records with existing ones.  This ensures that
    # only the correct and most up-to-date records exist in the database.
    # The sync process is as follows:
    # * Any existing record that doesn't match is deleted
    # * Existing records with matches are updated based on the given attributes for that record
    # * Records that don't exist are created
    # 
    # To create records that can be referenced elsewhere in the database, an
    # id should always be specified.  Otherwise, records may change id each
    # time they are bootstrapped.
    # 
    # == Examples
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
    # In the above model, the +colors+ table will be synchronized with the 3
    # records passed into the +bootstrap+ helper.  Any existing records that
    # do not match those 3 are deleted.  Otherwise, they are either created or
    # updated with the attributes specified.
    # 
    # == Defaults
    # 
    # In addition to *always* synchronizing certain attributes, an additional
    # +defaults+ option can be given to indicate that certain attributes
    # should only be synchronized if they haven't been modified in the
    # database.
    # 
    # For example,
    # 
    #   class Color < ActiveRecord::Base
    #     enumerate_by :name
    #     
    #     bootstrap(
    #       {:id => 1, :name => 'red', :defaults => {:html => '#f00'}},
    #       {:id => 2, :name => 'blue', :defaults => {:html => '#0f0'}},
    #       {:id => 3, :name => 'green', :defaults => {:html => '#00f'}}
    #     )
    #   end
    # 
    # In the above model, the +name+ attribute will always be updated on
    # existing records in the database.  However, the +html+ attribute will
    # only be synchronized if the attribute is nil in the database.
    # Otherwise, any changes to that column remain there.
    def bootstrap(*records)
      uncached do
        primary_key = self.primary_key.to_sym
        
        # Remove records that are no longer being used
        records.flatten!
        ids = records.map {|record| record[primary_key]}.compact
        delete_all(ids.any? ? ["#{primary_key} NOT IN (?)", ids] : nil)
        
        # Find remaining existing records (to be updated)
        existing = all.inject({}) {|existing, record| existing[record.send(primary_key)] = record; existing}
        
        records.map! do |attributes|
          attributes.symbolize_keys!
          defaults = attributes.delete(:defaults)
          
          # Update with new attributes
          record =
            if record = existing[attributes[primary_key]]
              attributes.merge!(defaults.delete_if {|attribute, value| record.send("#{attribute}?")}) if defaults
              record.attributes = attributes
              record
            else
              attributes.merge!(defaults) if defaults
              new(attributes)
            end
          record.send("#{primary_key}=", attributes[primary_key])
          
          # Force failed saves to stop execution
          record.save!
          record
        end
        
        records
      end
    end
    
    # Quickly synchronizes the given records with the existing ones.  This
    # skips ActiveRecord altogether, interacting directly with the connection
    # instead.  As a result, certain features are not available when being
    # bootstrapped, including:
    # * Callbacks
    # * Validations
    # * Transactions
    # * Timestamps
    # * Dirty attributes
    # 
    # Also note that records are created directly without creating instances
    # of the model.  As a result, all of the attributes for the record must be
    # specified.
    # 
    # This produces a significant performance increase when bootstrapping more
    # than several hundred records.
    # 
    # See EnumerateBy::Bootstrapped#bootstrap for information about usage.
    def fast_bootstrap(*records)
      primary_key = self.primary_key.to_sym
      
      # Remove records that are no longer being used
      records.flatten!
      ids = records.map {|record| record[primary_key]}.compact
      delete_all(ids.any? ? ["#{primary_key} NOT IN (?)", ids] : nil)
      
      # Find remaining existing records (to be updated)
      quoted_table_name = self.quoted_table_name
      existing = connection.select_all("SELECT * FROM #{quoted_table_name}").inject({}) {|existing, record| existing[record[primary_key.to_s].to_i] = record; existing}
      
      records.each do |attributes|
        attributes.stringify_keys!
        if defaults = attributes.delete('defaults')
          defaults.stringify_keys!
        end
        
        id = attributes[primary_key.to_s]
        if existing_attributes = existing[id]
          # Record exists: Update attributes
          attributes.delete(primary_key.to_s)
          attributes.merge!(defaults.delete_if {|attribute, value| !existing_attributes[attribute].nil?}) if defaults
          update_all(attributes, primary_key => id)
        else
          # Record doesn't exist: create new one
          attributes.merge!(defaults) if defaults
          column_names = []
          values = []
          
          attributes.each do |column_name, value|
            column_names << connection.quote_column_name(column_name)
            values << connection.quote(value, columns_hash[column_name])
          end
          
          connection.insert(
            "INSERT INTO #{quoted_table_name} (#{column_names * ', '}) VALUES(#{values * ', '})",
            "#{name} Create", primary_key, id, sequence_name
          )
        end
      end
      
      true
    end
  end
  
  module InstanceMethods
    # Whether or not this record is equal to the given value. If the value is
    # a String, then it is compared against the enumerator.  Otherwise,
    # ActiveRecord's default equality comparator is used.
    def ==(arg)
      arg.nil? || arg.is_a?(self.class) ? super : self == self.class.find_by_enumerator!(arg)
    end
    
    # Determines whether this enumeration is in the given list.
    # 
    # For example,
    # 
    #   color = Color.find_by_name('red')   # => #<Color id: 1, name: "red">
    #   color.in?('green')                  # => false
    #   color.in?('red', 'green')           # => true
    def in?(*list)
      list.any? {|item| self === item}
    end
    
    # A helper method for getting the current value of the enumerator
    # attribute for this record.  For example, if this record's model is
    # enumerated by the attribute +name+, then this will return the current
    # value for +name+.
    def enumerator
      send(enumerator_attribute)
    end
    
    # Stringifies the record typecasted to the enumerator value.
    # 
    # For example,
    # 
    #   color = Color.find_by_name('red')   # => #<Color id: 1, name: "red">
    #   color.to_s                          # => "red"
    def to_s
      to_str
    end
    
    # Add support for equality comparison with strings
    def to_str
      enumerator.to_s
    end
  end
end

ActiveRecord::Base.class_eval do
  extend EnumerateBy::MacroMethods
end
