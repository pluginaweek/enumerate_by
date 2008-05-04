class Country < ActiveRecord::Base
  acts_as_enumeration
  
  has_many  :regions
  has_one   :language
end
