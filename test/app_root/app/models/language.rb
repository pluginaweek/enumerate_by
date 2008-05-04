class Language < ActiveRecord::Base
  acts_as_enumeration
  
  column :country_id
  
  belongs_to :country
end
