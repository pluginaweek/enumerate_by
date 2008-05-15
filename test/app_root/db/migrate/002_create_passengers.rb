class CreatePassengers < ActiveRecord::Migration
  def self.up
    create_table :passengers do |t|
      t.references :car
    end
  end
  
  def self.down
    drop_table :passengers
  end
end
