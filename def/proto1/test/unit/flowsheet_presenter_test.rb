require 'test_helper'
require File.expand_path( '../presenter_test_base', __FILE__)

class FlowsheetPresenterTest < ActiveSupport::TestCase
  include PresenterTestBase

  fixtures :users

  # Tests that the lists the presenter needs get loaded
  def test_lists
    p = FlowsheetPresenter.new
    assert p.group_by_list.size > 0
  end

  def test_process_params
    # Both date fields wrong, but the customize option is not selected.
    p = FlowsheetPresenter.new(nil, {:start_date=>'asdf', :end_date=>'adsf'})
    assert_nil p.process_params

    # Both date fields wrong
    p = FlowsheetPresenter.new(nil, {:start_date=>'asdf', :end_date=>'adsf',
      :date_range_C=>'7'}) # 7 = Custom date range
    assert_equal 2, p.process_params.size

    # One date field is wrong
    p = FlowsheetPresenter.new(nil, {:start_date=>'2012/4/2', :end_date=>'adsf',
      :date_range_C=>'7'})
    assert_equal 1, p.process_params.size

    # One field is an invalid date
    p = FlowsheetPresenter.new(nil, {:start_date=>'2012/4/42',
      :end_date=>'2012/4/3', :date_range_C=>'7'})
    assert_equal 1, p.process_params.size
    assert_nil p.data.start_date_ET

    # Both fields are okay
    p = FlowsheetPresenter.new(nil, {:start_date=>'2012/4/2',
      :end_date=>'2012/4/3', :date_range_C=>'7'})
    assert p.process_params.nil?
    assert_not_nil p.data.start_date_ET


    # Test the updates to the selected panels.
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items',
        'loinc_items', 'loinc_panels', 'loinc_units'], false)
    user = users(:PHR_Test)
    profile = Profile.create!(:id_shown=>Time.now.to_i.to_s)
    user.profiles << profile
    phr = Phr.create!(:pseudonym=>Time.now.to_i.to_s, :gender_C=>'M', :latest=>1,
     :birth_date=>'1950/1/2', :profile_id=>profile.id)

    fp = FlowsheetPresenter.new(profile, {:panels=>{'one'=>'1', 'two'=>'1'}})
    assert_nil fp.process_params
    assert_equal Set.new(['one', 'two']), fp.selected_panels
  end
end
