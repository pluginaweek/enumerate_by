class CreateCars < ActiveRecord::Migration
  def self.up
    create_table :cars do |t|
      t.string :name
      t.references :color
      t.references :feature, :class_name => 'Color', :polymorphic => true
    end
  end
  
  def self.down
    drop_table :cars
  end
end
