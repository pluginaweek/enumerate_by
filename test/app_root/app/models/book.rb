class Book < ActiveRecord::Base
  acts_as_enumeration :title
end
