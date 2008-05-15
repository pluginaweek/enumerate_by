class Manufacturer < ActiveRecord::Base
  acts_as_enumeration
  
  has_many :cars
  
  create :id => 1, :name => 'ford'
  create :id => 2, :name => 'chevy'
end
