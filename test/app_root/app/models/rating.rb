class Rating < ActiveRecord::Base
  acts_as_enumeration :virtual => true
  
  create :id => 1, :name => 'good'
  create :id => 2, :name => 'bad'
  create :id => 3, :name => 'ugly'
end
