class Car < ActiveRecord::Base
  belongs_to :color
  belongs_to :rating
end
