require 'test_helper'

class ClassificationTest < ActiveSupport::TestCase
  #fixtures :rules
  def setup
    Classification.destroy_all
  end

  def test_get_list_items
    root_id= "12345"
    
    list_desc = ListDescription.new(:item_master_table=>"test_table")
    list_desc.save!
    drug_class_type = Classification.new(
      :class_name=>"Testing_Drug", :class_code=>"testing_drug",
      :list_description=>list_desc, :class_type_id => root_id)
    drug_class_type.save!
    drug_class_a = Classification.new(:class_type_id=>drug_class_type.id) 
    drug_class_a.class_name = "class_a"
    drug_class_a.class_code = "class_a"
    drug_class_a.list_description = list_desc
    drug_class_a.sequence = 1
    drug_class_a.save!
    drug_class_b = Classification.new(:class_type_id=>drug_class_type.id) 
    drug_class_b.class_name = "class_b"
    drug_class_b.class_code = "class_b"
    drug_class_b.list_description = list_desc
    drug_class_b.sequence = 2
    drug_class_b.save!
    class_names = Classification.get_list_items("testing_drug").map(&:class_name)
    assert_equal %w(class_a class_b), class_names
  end

end
