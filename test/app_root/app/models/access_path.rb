class AccessPath < ActiveRecord::Base
  acts_as_enumeration :controller, :action
end
