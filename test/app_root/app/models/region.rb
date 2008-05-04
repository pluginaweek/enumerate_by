class Region < ActiveRecord::Base
  acts_as_enumeration
  
  column :country_id, :integer
  
  belongs_to :country
end
