class Rating < ActiveRecord::Base
  acts_as_enumeration :virtual => true
  
  def self.enumerations
    [
      Rating.new(:id => 1, :name => 'good'),
      Rating.new(:id => 2, :name => 'bad'),
      Rating.new(:id => 3, :name => 'ugly')
    ]
  end
end
