# Records in this table represent a lock on some resource.  When a process
# needs to lock something, it adds an entry here, and other processes that need
# to lock the same resource can use this class to see if the resource is locked.
class Lock < ActiveRecord::Base
  validates_uniqueness_of :resource_name
  validates_presence_of :resource_name
  validates_presence_of :user_id

end
