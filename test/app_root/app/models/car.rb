class Car < ActiveRecord::Base
  belongs_to  :color
  belongs_to  :manufacturer
  has_many    :passengers
end
