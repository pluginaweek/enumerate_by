module PluginAWeek #:nodoc:
  module ActsAsEnumeration
    # Adds support for converting a collection of enumerations to json.  This is
    # required since the JSON serializer will fail when comparing an
    # enumeration's attribute names with the actual enumeration.  Equality
    # comparison with enumerations requires that the string map to an actual
    # enumeration, otherwise an exception will be raised.
    class Collection < Array
      def to_json(options = {}) #:nodoc:
        "[#{map {|value| value.to_json(options)} * ', '}]"
      end
    end
  end
end
