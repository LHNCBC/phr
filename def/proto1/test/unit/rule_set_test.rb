require 'test_helper'


class RuleSetTest < ActiveSupport::TestCase

  def setup
    RuleSet.delete_all
    @form = Form.create(:form_name => "foo")
    @rule_set = RuleSet.create(:name=> "rule set 1",
      :content=> "item 1, item 2, item 3")
    @form.rule_sets << @rule_set
  end

  def test_load_rule_set_data
    expected= {"rule set 1"=>{"item 1"=>1, "item 2"=>1, "item 3"=>1}}
    assert_equal(expected,  RuleSet.load_rule_set_data(@form))
  end
  
  def test_data_hash_for_display
    expected = {"rule_sets"=>
        [{"edit_rule_set"=>"#{@rule_set.id};edit",
          "rule_set_name"=>"rule set 1",
          "rule_set_content"=>"item 1, item 2, item 3",
          "delete_rule_set"=>"#{@rule_set.id}"}]}
    assert_equal(expected, RuleSet.data_hash_for_display)
  end
  
  # TODO: pending, need to be implemented asap
  def test_data_hash_for_set_edit_page
  end

end
