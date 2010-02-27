class CreateLegacyColors < ActiveRecord::Migration
  def self.up
    create_table :legacy_colors, :primary_key => 'uid' do |t|
      t.string :name, :null => false
      t.string :html
    end
  end
  
  def self.down
    drop_table :legacy_colors
  end
end
