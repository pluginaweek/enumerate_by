class CreateOrders < ActiveRecord::Migration
  def self.up
    create_table :orders do |t|
      t.string :state
      t.references :car_part
    end
  end
  
  def self.down
    drop_table :orders
  end
end
