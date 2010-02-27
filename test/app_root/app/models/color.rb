class Color < ActiveRecord::Base
  enumerate_by :name
  
  has_many :cars
end
