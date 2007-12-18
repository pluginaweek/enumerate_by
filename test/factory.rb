module Factory
  def new_car(options = {})
    Car.new(options.reverse_merge(
      :name => 'Ford Mustang',
      :color_id => 1
    ))
  end
  
  def new_color(options = {})
    Color.new(options.reverse_merge(
      :id => 1,
      :name => 'red'
    ))
  end
  
  # Add create actions
  instance_methods.each do |method|
    module_eval <<-end_eval
      def #{method.sub(/^new/, 'create')}(*args)
        record = #{method}(*args)
        record.save!
        record.reload
        record
      end
    end_eval
  end
end
