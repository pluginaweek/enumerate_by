module PluginAWeek #:nodoc:
  module Acts #:nodoc:
    module Enumerated #:nodoc:
      def self.included(base) #:nodoc:
        base.extend(MacroMethods)
      end
      
      module MacroMethods
        #
        #
        def acts_as_enumerated(options = {})
          valid_keys = [
            :conditions,
            :order,
            :on_lookup_failure
          ]
          options.assert_valid_keys(*valid_keys)
          valid_keys.each do |key|
            write_inheritable_attribute("acts_enumerated_#{key.to_s}".to_sym, options[key]) if options.has_key?(key)
          end
          
          validates_uniqueness_of :name
          
          before_save :enumeration_model_update
          before_destroy :enumeration_model_update
          
          extend PluginAWeek::Acts::Enumerated::ClassMethods
          include PluginAWeek::Acts::Enumerated::InstanceMethods
        end
      end
      
      module ClassMethods
        attr_accessor :enumeration_model_updates_permitted
        
        #
        #
        def all
          @all ||= find(:all,
            :conditions => read_inheritable_attribute(:acts_enumerated_conditions),
            :order => read_inheritable_attribute(:acts_enumerated_order)
          ).map(&:freeze).freeze
        end
        
        #
        #
        def [](arg)
          case arg
            when Symbol
              value = lookup_name(arg.id2name)
            when String
              value = lookup_name(arg)
            when Fixnum
              value = lookup_id(arg)
            when nil
              value = nil
            else
              raise TypeError, "#{self.name}[]: argument should be a String, Symbol or Fixnum but got a: #{arg.class.name}"
          end
          
          if value.nil?
            self.send((read_inheritable_attribute(:acts_enumerated_on_lookup_failure) || :enforce_strict_literals), arg)
          end
          
          return value
        end
        
        #
        #
        def lookup_id(arg)
          all_by_id[arg]
        end
        
        #
        #
        def lookup_name(arg)
          all_by_name[arg]
        end
        
        #
        #
        def includes?(arg)
          value = self[arg]
          !value.nil? && arg === self ? value == arg : true
        end
        
        # NOTE: purging the cache is sort of pointless because of the per-process rails model.
        # By default this blows up noisily just in case you try to be more clever than rails allows.
        # For those times (like in Migrations) when you really do want to alter the records
        # you can silence the carping by setting enumeration_model_updates_permitted to true.
        def purge_enumerations_cache
          raise "#{self.name}: cache purging disabled for your protection" unless self.enumeration_model_updates_permitted
          
          @all = @all_by_name = @all_by_id = nil
        end
        
        private
        #
        #
        def all_by_id
          @all_by_id ||= all.inject({}) {|memo, item| memo[item.id] = item; memo;}.freeze
        end
        
        #
        #
        def all_by_name
          begin
            @all_by_name ||= all.inject({}) {|memo, item| memo[item.name] = item; memo;}.freeze
          rescue NoMethodError => err
            if err.name == :name
              raise TypeError, "#{self.name}: you need to define a 'name' column in the table '#{table_name}'"
            else
              raise
            end
          end
        end
        
        #
        #
        def enforce_none(arg)
        end
        
        #
        #
        def enforce_strict(arg)
          raise ActiveRecord::RecordNotFound, "Couldn't find a #{self.name} identified by (#{arg.inspect})"
        end
        
        #
        #
        def enforce_strict_literals(arg)
          raise ActiveRecord::RecordNotFound, "Couldn't find a #{self.name} identified by (#{arg.inspect})" if Fixnum === arg || Symbol === arg
        end
      end
      
      module InstanceMethods
        #
        #
        def ===(arg)
          case arg
            when Symbol, String, Fixnum, nil
              return self == self.class[arg]
            when Array
              return in?(*arg)
            end
          super
        end
        alias_method :like?, :===
        
        #
        #
        def in?(*list)
          list.any? {|item| self === item}
        end
        
        #
        #
        def name_sym
          self.name.to_sym
        end
        
        private
        # NOTE: updating the models that back an acts_as_enumerated is
        # rather dangerous because of rails' per-process model.
        # The cached values could get out of synch between processes
        # and rather than completely disallow changes I make you jump 
        # through an extra hoop just in case you're defining your enumeration
        # values in Migrations.  I.e. set enumeration_model_updates_permitted = true
        def enumeration_model_update
          if self.class.enumeration_model_updates_permitted
            self.class.purge_enumerations_cache
            true
          else
            errors.add('name', "changes to acts_as_enumeration model instances are not permitted")
            false
          end
        end
      end
    end
  end
end