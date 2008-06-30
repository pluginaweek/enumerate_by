class CreateAmbassadors < ActiveRecord::Migration
  def self.up
    create_table :ambassadors do |t|
      t.references :country
      t.string :name
    end
  end
  
  def self.down
    drop_table :ambassadors
  end
end
