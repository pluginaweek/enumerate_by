class CreateCarParts < ActiveRecord::Migration
  def self.up
    create_table :car_parts do |t|
      t.string :name
      t.integer :number
    end
  end
  
  def self.down
    drop_table :car_parts
  end
end
