class Car < ActiveRecord::Base
  belongs_to  :color,
                :enumerated => true
end