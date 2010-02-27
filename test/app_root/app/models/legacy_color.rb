class LegacyColor < ActiveRecord::Base
  set_primary_key :uid
  
  enumerate_by :name
end
