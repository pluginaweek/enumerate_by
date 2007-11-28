class CreateCars < ActiveRecord::Migration
  def self.up
    create_table :cars do |t|
      t.column :manufacturer, :string, :null => false
      t.column :model, :string, :null => false
      t.column :year, :integer, :null => false
      t.column :color_id, :integer, :null => false
      t.column :rating_id, :integer, :null => false
    end
  end
  
  def self.down
    drop_table :cars
  end
end
