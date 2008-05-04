class CreateCars < ActiveRecord::Migration
  def self.up
    create_table :cars do |t|
      t.string :name, :null => false
      t.integer :color_id, :null => false
      t.integer :manufacturer_id
    end
  end
  
  def self.down
    drop_table :cars
  end
end
