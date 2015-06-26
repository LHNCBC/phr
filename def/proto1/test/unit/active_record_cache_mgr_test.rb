require 'test_helper'

class ActiveRecordCacheMgrTest < ActiveSupport::TestCase

  # Note:  The following test is not effective unless USE_AR_CACHE
  # is set to true (in environment.rb).  However, other tests won't work
  # with that setting, and by the time this runs it is probably too late
  # to change the setting.
  def test_cache_find_calls
    # Here I am just testing that that a bug with the find method
    # is now fixed.  In the bug, if you used, "find_by_" and also specified a
    # condition, the field specified in the "find_by" would effectively get
    # lost (when the cache was used).
    # Create two entries for a loinc panel.
    LoincPanel.destroy_all
    lp1 = LoincPanel.create!({"p_id"=>1, "default_value"=>nil, "observation_required_in_panel"=>nil, "loinc_item_id"=>3728, "observation_required_in_phr"=>nil, "answer_required"=>false, "type_of_entry"=>"Q", "loinc_num"=>"13361-1", "sequence_num"=>1})
    lp2 = LoincPanel.create!({"p_id"=>1, "default_value"=>nil, "observation_required_in_panel"=>nil, "loinc_item_id"=>23589, "observation_required_in_phr"=>nil, "answer_required"=>false, "type_of_entry"=>"Q", "loinc_num"=>"3160-9", "sequence_num"=>1})
    assert_equal(lp1.id,
      LoincPanel.where(loinc_num: '13361-1', p_id: 1).first.id)
    assert_equal(lp2.id,
      LoincPanel.where(loinc_num: '3160-9', p_id: 1).first.id)
  end
end
