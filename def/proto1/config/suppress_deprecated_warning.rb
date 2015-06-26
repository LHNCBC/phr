# suppress deprecated BasicObject which is used by acts_as_ferret Gem as of now - 10/31/2013 Frank
module ActiveSupport
  class BasicObject < ProxyObject # :nodoc:
    def self.inherited(*)
      super
    end
  end
end