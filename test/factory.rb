module Factory
  # Build actions for the class
  def self.build(klass, &block)
    name = klass.to_s.underscore
    define_method("#{name}_attributes", block)
    
    module_eval <<-end_eval
      def valid_#{name}_attributes(attributes = {})
        #{name}_attributes(attributes)
        attributes
      end
      
      def new_#{name}(attributes = {})
        #{klass}.new(valid_#{name}_attributes(attributes))
      end
      
      def create_#{name}(*args)
        record = new_#{name}(*args)
        record.save!
        record.reload
        record
      end
    end_eval
  end
  
  build AccessPath do |attributes|
    attributes.reverse_merge!(
      :id => 1,
      :controller => 'users',
      :action => 'index'
    )
  end
  
  build Book do |attributes|
    attributes.reverse_merge!(
      :id => 1,
      :title => 'Blink'
    )
  end
  
  build Car do |attributes|
    attributes.reverse_merge!(
      :name => 'Ford Mustang',
      :color_id => 1
    )
  end
  
  build Color do |attributes|
    attributes.reverse_merge!(
      :id => 1,
      :name => 'red'
    )
  end
  
  build Country do |attributes|
    attributes.reverse_merge!(
      :id => 1,
      :name => 'United States'
    )
  end
  
  build Language do |attributes|
    attributes[:country] ||= create_country unless attributes.include?(:country)
    attributes.reverse_merge!(
      :id => 1,
      :name => 'English'
    )
  end
  
  build Region do |attributes|
    attributes[:country] ||= create_country unless attributes.include?(:country)
    attributes.reverse_merge!(
      :id => 1,
      :name => 'New Jersey'
    )
  end
end
