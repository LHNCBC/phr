require 'test_helper'

class DrugNameRouteCodeTest < ActiveSupport::TestCase

  def test_next_code
    DrugNameRouteCode.delete_all
    # Hack to reset internal counter
    eval_string =<<ENDCLS
      class ::DrugNameRouteCode
        def self.reset
          @@last_next_code = nil
        end
      end
ENDCLS
    eval(eval_string)
    DrugNameRouteCode.reset
    assert_equal(1, DrugNameRouteCode.next_code)
    assert_equal(2, DrugNameRouteCode.next_code)
    DrugNameRouteCode.create!(:code=>15, :long_code=>'green')
    DrugNameRouteCode.reset
    assert_equal(16, DrugNameRouteCode.next_code)
    assert_equal(17, DrugNameRouteCode.next_code)
  end

end
