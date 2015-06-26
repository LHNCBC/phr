# This is a patch for the bug introduced by Rails 4.1.5 and will be removed in Rails 4.2 (see
# https://github.com/rails/rails/issues/15594). In the next Rails upgrading, this class and all the usages of
# this class should be cleaned up if the bug is fixed in the newer version of Rails. - Frank
class JsonProxy

  def self.dump(object)
    ActiveSupport::JSON.encode(object) unless object.nil?
  end

  def self.load(string)
    ActiveSupport::JSON.decode(string) if string.present?
  end

end