require 'test_helper'

class FormTest < ActiveSupport::TestCase
  fixtures :predefined_fields

  def setup
    Form.destroy_all
    FieldDescription.destroy_all

    # Create a form(i.e. @form) with some fields(i.e. @foreign_fld) coming from 
    # other forms (i.e. @form_2)
    @form = Form.create!(:form_name => "test form") 
    @f = FieldDescription.create!(:display_name => "test field", 
      :control_type => "test_panel",
      :control_type_detail => {'panel_name'=>'includedform'},
      :predefined_field_id => predefined_fields(:one).id,
      :target_field => "abc",
      :form_id => @form.id,
      :display_order=>10
    )

    @form_2 = Form.create!(:form_name => "includedform") 
    @foreign_fld= FieldDescription.create!(:display_name => "subform f1", 
      :control_type => "text_field",
      :control_type_detail => '',
      :predefined_field_id => predefined_fields(:one).id,
      :target_field => "abc1",
      :form_id => @form_2.id
    )
    @r_2 = Rule.create(:name => "r", :expression => "'d'", :forms => [@form_2])
    @foreign_fld.rules << @r_2
  end
   

  def test_foreign_fields_with_rules
    # should return foreign fields
    actual = @form.foreign_fields_with_rules
    expected = [@foreign_fld]
    assert_equal(expected, actual)

    # also return the associated rules
    actual = @form.foreign_fields_with_rules.map(&:rules).flatten
    expected = [@r_2]
    assert_equal(expected, actual)
  end

  def test_foreign_fields
    foreign_fld2 = FieldDescription.create!(
      :display_name => "subform f2",
      :control_type => "text_field",
      :control_type_detail => '',
      :predefined_field_id => predefined_fields(:one).id,
      :target_field => "abc2",
      :form_id => @form_2.id
    )

    foreign_fld3 = FieldDescription.create!(
      :display_name => "subform f3",
      :control_type => "text_field",
      :control_type_detail => '',
      :predefined_field_id => predefined_fields(:one).id,
      :target_field => "abb",
      :form_id => @form_2.id
    )
    actual = @form.foreign_fields(nil, 'target_field')
    expected = [foreign_fld3, @foreign_fld, foreign_fld2]
    assert_equal(expected, actual)

    actual = @form.foreign_fields("target_field != 'abb'", 'target_field')
    expected = [@foreign_fld, foreign_fld2]
    assert_equal(expected, actual)

    actual = @form.foreign_fields(nil, nil)
    expected = [@foreign_fld, foreign_fld2, foreign_fld3]
    assert_equal(expected, actual)
  end

  # Tests help_text_csv_dump
  def test_help_text_csv_dump
    fd2 = FieldDescription.create!(:display_name=>'A Group Header',
      :control_type => 'group_hdr',
      :predefined_field_id => predefined_fields(:group_header).id,
      :target_field => 'a_group_header',
      :display_order=>20,
      :form_id => @form.id)
    fd3 = FieldDescription.create!(:display_name=>'A sub field',
      :control_type => 'text_field',
      :predefined_field_id => predefined_fields(:one).id,
      :target_field => 'a_sub_field',
      :form_id => @form.id,
      :display_order=>30,
      :default_value=>'hello',
      :group_header_id => fd2.id)
    fd4 = FieldDescription.create!(:display_name=>'A static_text',
      :control_type => 'static_text',
      :predefined_field_id => predefined_fields(:static_text).id,
      :target_field => 'some_static_text',
      :form_id => @form.id,
      :display_order=>30,
      :default_value=>'one',
      :group_header_id => fd2.id)
      
    csv = @form.help_text_csv_dump
    lines = csv.split("\n")
    assert_equal(6, lines.length) # there is one field we created in setup
    first_line_fields = lines[0].split(/,/)
    assert_equal('field_descriptions', first_line_fields[1])
    assert_equal(@form.form_name, first_line_fields[3])
    assert_equal('id,display_name,Section Name,control_type,help_text,'+
                 'instructions,default_value,width,min_width,tooltip', lines[1])
    # Check the second field, which has no group header.
    assert_equal("#{fd2.id},#{fd2.display_name},\"\",group_hdr,,,,,,", lines[3])
    assert(lines[3] =~ /A Group Header/)
    
    # Check the third field, which has a group header
    assert(lines[4].index('A Group Header'))
    assert(lines[4] =~ /A sub field/)
    
    # Check the fourth field (static_text)
    assert(lines[5].index('A static_text'))
    assert(lines[5].index('one'))
  end
  
  
  #  Tests help_text_csv_update
  def test_help_text_csv_update
    fd2 = FieldDescription.create!(:display_name=>'A Group Header',
      :control_type => 'group_hdr',
      :predefined_field_id => predefined_fields(:group_header).id,
      :target_field => 'a_group_header',
      :display_order=>20,
      :default_value=>'green',
      :form_id => @form.id)
    fd3 = FieldDescription.create!(:display_name=>'A sub field',
      :control_type => 'text_field',
      :predefined_field_id => predefined_fields(:one).id,
      :target_field => 'a_sub_field',
      :form_id => @form.id,
      :display_order=>30,
      :group_header_id => fd2.id)
    fd4 = FieldDescription.create!(:display_name=>'A static_text',
      :control_type => 'static_text',
      :predefined_field_id => predefined_fields(:static_text).id,
      :target_field => 'a_sub_field2',
      :form_id => @form.id,
      :display_order=>30,
      :default_value=>'one',
      :group_header_id => fd2.id)
    ori_count = DataEdit.count
      
    # Try modifiying a FieldDescription.  Confirm that we can set the
    # help_text, and instructions, and the display_name field.
    # Also edit the default value of the static text field, and confirm
    # that we can change that default value but not the default value of
    # a field that is not static_text.
    # Also confirm that we cannot edit the control type.
    assert(fd2.help_text.blank?)
    csv_str = "id,display_name,Section Name,control_type,help_text,"+
      "instructions,default_value,width,min_width,tooltip\n#{fd2.id},"+
      'Help Button,,new_control_type,Help!,Head for the hills,blue' +
      "\n#{fd4.id},A static_text,,static_text,,,two,20em,10em"
    @form.help_text_csv_update(csv_str, 1)
    fd = FieldDescription.find_by_id(fd2.id)
    assert_equal('Help!', fd.help_text)
    assert_equal('Help Button', fd.display_name)
    assert_equal('Head for the hills', fd.instructions)
    assert_equal('green', fd.default_value)
    assert_equal('group_hdr', fd.control_type)
    fd4_again = FieldDescription.find_by_id(fd4.id)
    assert_equal('two', fd4_again.default_value)
    assert_equal('20em', fd4_again.width)
    assert_equal('10em', fd4_again.min_width)
    
    # Also confirm that we created a DataEdit record, and that we backed up
    # the right table
    des = DataEdit.all
    #assert_equal(1, des.size)
    assert_equal(1, des.size - ori_count)
    #assert(des[0].backup_file.index('.field_descriptions_'))
    assert(des.last.backup_file.index(/\.field_descriptions(_|\b)/))

    # Confirm that the backup file exists.
    #backup = des[0].backup_file
    backup = des.last.backup_file
    assert(File.exists?(backup))
    assert(File.size(backup))

    # Confirm that we can't create a new FieldDescription via the help
    # text update.
    num_FDs = FieldDescription.count
    csv_str = "id,help_text,display_name,control_type,instructions"+
      ",default_value,width,min_width,tooltip\n,New Item Help,,,,,,"
    assert_raise(RuntimeError) {@form.help_text_csv_update(csv_str, 1)}
    assert_equal(num_FDs, FieldDescription.count)

    # Confirm that we can't edit a new FieldDescription that doesn't belong
    # to the specified form.
    num_FDs = FieldDescription.count
    csv_str = "id,help_text,display_name,control_type,instructions"+
      ",default_value,width,min_width,tooltip\n1234567,New Item Help,,,,,,"
    assert_raise(RuntimeError) {@form.help_text_csv_update(csv_str, 1)}
    
    # Confirm that we can't delete a FieldDescription via the update.
    csv_str = "id,help_text,display_name,control_type,instructions"+
      ",default_value,width,min_width,tooltip\ndelete #{fd3.id},,,,,,,"
    assert_raise(ActiveRecord::StatementInvalid, RuntimeError) {
      @form.help_text_csv_update(csv_str, 1)}
    assert_equal(num_FDs, FieldDescription.count)
  end

  def test_data_field_labelnames
    actual = @form.data_field_labelnames.to_json
    expected = 
      "{\"abc\":[[\"test field\"],\"\"],\"abc1\":[[\"subform f1\"],\"\"]}"
    assert_equal expected, actual
  end

  def test_subform_associations
    current_form = Form.create!(:form_name => Time.now.to_i.to_s)
    subform = Form.create!(:form_name => Time.now.to_i.to_s + "123")
    
    # establish subform association
    sub_ct = FieldDescription::SUBFORM_CONTROL_TYPES.first
    sub_name_key = FieldDescription::SUBFORM_KEYS.first
    current_form.field_descriptions.create({
        :target_field => "subform_field",
        :control_type => sub_ct,
        :control_type_detail => {"#{sub_name_key}"=>"#{subform.form_name}"},
        :predefined_field_id => predefined_fields(:one).id,
      })
   
    # Tests uses_forms method
    actual = current_form.uses_forms 
    expected = [subform]
    assert_equal expected, actual
    
    # Tests used_by_forms method
    actual = subform.used_by_forms
    expected = [current_form]
    assert_equal expected, actual
  end
end
