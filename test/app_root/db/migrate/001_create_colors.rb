class CreateColors < ActiveRecord::Migration
  def self.up
    create_table :colors do |t|
      t.column :name, :string, :null => false
    end
  end
  
  def self.down
    drop_table :colors
  end
end