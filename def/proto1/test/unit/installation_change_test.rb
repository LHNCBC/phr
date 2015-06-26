require 'test_helper'

class InstallationChangeTest < ActiveSupport::TestCase
  # Refine a model class whose validation we don't care about for this
  # test.  No validation => no need to copy dependent tables.
  class Form < ActiveRecord::Base
  end

  def test_perform
    f = Form.create!(form_name: 'inst_change_test', form_title: 'Default title')
    ic = InstallationChange.create!(table_name: 'forms', column_name: 'form_title',
      record_id: f.id, value: 'Special title', installation: 'special')
    assert_equal(1, InstallationChange.where(table_name: 'forms',
      record_id: f.id).count)
    pre_ic_count =  InstallationChange.count
    ic.perform
    # Check the installation changes table
    assert_equal(pre_ic_count+1, InstallationChange.count)
    assert_equal(2, InstallationChange.where(table_name: 'forms',
      record_id: f.id).count)
    assert_equal(1, InstallationChange.where(table_name: 'forms',
      record_id: f.id,
      installation: InstallationChange::INSTALLATION_NAME_DEFAULT).count)
    # Check the forms table
    assert_equal('Special title', Form.find(f.id).form_title)

    # Now return to the default mode (undo this change)
    default_ic = InstallationChange.where(table_name: 'forms',
      record_id: f.id,
      installation: InstallationChange::INSTALLATION_NAME_DEFAULT).take
    default_ic.perform
    # Check the installation changes table
    assert_equal(1, InstallationChange.where(table_name: 'forms',
      record_id: f.id).count)
    assert_equal(pre_ic_count, InstallationChange.count)
    assert_equal('Special title', InstallationChange.where(table_name: 'forms',
      record_id: f.id).take.value)
    # Check the forms table
    assert_equal('Default title', Form.find(f.id).form_title)
  end
end
