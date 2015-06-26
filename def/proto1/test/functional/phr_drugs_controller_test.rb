require 'test_helper'

class PhrDrugsControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @request.env['HTTPS'] = 'on'  # Set the request to be SSL

    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
        'db_field_descriptions', 'db_table_descriptions', 'forms', 'text_lists',
        'text_list_items', 'drug_name_routes'], true,
        'text_lists'=>'list_name in ("Drug Use Status", "why_stopped", "Gender")',
        'text_list_items'=>'text_list_id in (55, 59, 21)', 'forms'=>'id=7',
        'field_descriptions'=>'form_id=7', 'drug_name_routes'=>'code=27675',
        'db_table_descriptions'=>'data_table in ("phr_drugs", "phrs")',
        'db_field_descriptions'=>'db_table_description_id in (7,13)')
    # The user data models have been loaded previously but some user tables seem to be missing at that time.
    # Do it again here after coping db_table_descriptions from development db
    DbTableDescription.define_user_data_models
    @drug_info = DrugNameRoute.find_by_code(27675) # ARAVA (Oral Pill)
    DatabaseMethod.copy_development_tables_to_test(['drug_strength_forms'], false,
        'drug_strength_forms'=>"drug_name_route_id=#{@drug_info.id}")

    DbTableDescription.define_user_data_models

    # Create a profile and a drug record, for testing
    user = users(:PHR_Test)
    @profile = Profile.create!(:id_shown=>Time.now.to_i.to_s)
    user.profiles << @profile
    p = Phr.create!(:pseudonym=>Time.now.to_i.to_s, :gender_C=>'M', :latest=>1,
     :profile_id=>@profile.id, :birth_date=>'1950/1/2')
  end


  # Tests index search, new, edit, create, update, and destroy
  def test_actions
    session_data = {:user_id=>users(:PHR_Test).id, :cur_ip=>'127.11.11.11'}
    form_data = {:phr_record_id=>@profile.id_shown}

    get :index, form_data, session_data
    assert_response :success
    assert_nil flash[:error]
    assert_nil flash[:notice]

    access_det = UsageStat.where(profile_id: @profile.id).
                           order('event_time desc').to_a
    assert_equal(1, access_det.size)
    det = access_det[0]
    assert_equal('valid_access', det.event)
    assert_equal("https://test.host/", det.data['url'][0,18])

    # Check the new action
    get :new, form_data, session_data
    assert_response :success
    assert_nil flash[:error]
    assert_select('input#phr_search_text')

    # Check the search action
    form_data[:phr] = {:search_text=>'ar'}
    form_data[:id] = 'new'
    get :search, form_data, session_data
    assert_response :success
    assert_select('ul') # the list

    # Continue to the new page
    form_data[:code] = 4727
    form_data.delete(:search_text)
    get :new, form_data, session_data
    assert_response :success
    assert_select('input#phr_name_and_route')

    # More TBD
  end


  test "Updates to list fields" do
    known_drug = PhrDrug.create!(:profile_id=>@profile.id, :latest=>1,
      :name_and_route_C=>'27675', :drug_use_status_C=>'DRG-A')
    dr = @drug_info

    # Update it with blank data for the drug field
    session_data = {:user_id=>users(:PHR_Test).id, :cur_ip=>'127.11.11.11'}
    update_data = {:phr=>{:instructions=>'hi',
      :name_and_route=>known_drug.name_and_route,
      :drug_use_status_C=>'DRG-A',
      :drug_strength_form_C=>'', :alt_drug_strength_form=>''},
      :id=>known_drug.id, :phr_record_id=>@profile.id_shown}
    put :update, update_data, session_data

    assert_redirected_to :controller=>'phr_drugs', :action=>:index
    # Confirm that the drug strength is blank
    updated_rec = @profile.phr_drugs.find_by_id(known_drug.id)
    assert(updated_rec.drug_strength_form_C.blank?)
    assert(updated_rec.drug_strength_form.blank?)

    # Update it with a known strength value
    strength_code = dr.drug_strength_forms[0].rxcui.to_s
    strength_text = dr.drug_strength_forms[0].text
    update_data[:phr][:drug_strength_form_C] = strength_code
    put :update, update_data, session_data
    assert_redirected_to :controller=>'phr_drugs', :action=>:index
    updated_rec = @profile.phr_drugs.find_by_id(known_drug.id)
    assert_equal(strength_code, updated_rec.drug_strength_form_C)
    assert_equal(strength_text, updated_rec.drug_strength_form)

    # Update it with a different known strength value
    strength_code = dr.drug_strength_forms[1].rxcui.to_s
    strength_text = dr.drug_strength_forms[1].text
    update_data[:phr][:drug_strength_form_C] = strength_code
    put :update, update_data, session_data
    assert_redirected_to :controller=>'phr_drugs', :action=>:index
    updated_rec = @profile.phr_drugs.find_by_id(known_drug.id)
    assert_equal(strength_code, updated_rec.drug_strength_form_C)
    assert_equal(strength_text, updated_rec.drug_strength_form)

    # Update some other part of the record, without changing the strength
    update_data[:phr][:instructions] = 'one'
    put :update, update_data, session_data
    assert_redirected_to :controller=>'phr_drugs', :action=>:index
    updated_rec = @profile.phr_drugs.find_by_id(known_drug.id)
    assert_equal('one', updated_rec.instructions)
    assert_equal(strength_code, updated_rec.drug_strength_form_C)
    assert_equal(strength_text, updated_rec.drug_strength_form)

    # Use the alternate text field for the strength (non-coded value)
    update_data[:phr][:alt_drug_strength_form] = 'some'
    put :update, update_data, session_data
    assert_redirected_to :controller=>'phr_drugs', :action=>:index
    updated_rec = @profile.phr_drugs.find_by_id(known_drug.id)
    assert(updated_rec.drug_strength_form_C.blank?)
    assert_equal('some', updated_rec.drug_strength_form)

    # Again, update some other part of the form without setting the strength
    update_data[:phr][:instructions] = 'two'
    update_data[:phr][:drug_strength_form_C] = '' # should have appeared as such on the form
    put :update, update_data, session_data
    assert_redirected_to :controller=>'phr_drugs', :action=>:index
    updated_rec = @profile.phr_drugs.find_by_id(known_drug.id)
    assert_equal('two', updated_rec.instructions)
    assert(updated_rec.drug_strength_form_C.blank?)
    assert_equal('some', updated_rec.drug_strength_form)

    # Pick a coded value
    update_data[:phr][:drug_strength_form_C] = strength_code
    put :update, update_data, session_data
    assert_redirected_to :controller=>'phr_drugs', :action=>:index
    updated_rec = @profile.phr_drugs.find_by_id(known_drug.id)
    assert_equal('two', updated_rec.instructions)
    assert_equal(strength_code, updated_rec.drug_strength_form_C)
    assert_equal(strength_text, updated_rec.drug_strength_form)

    # Set the coded value to blank
    update_data[:phr][:alt_drug_strength_form] = '' # should have appeared as such on the form
    update_data[:phr][:drug_strength_form_C] = ''
    put :update, update_data, session_data
    assert_redirected_to :controller=>'phr_drugs', :action=>:index
    updated_rec = @profile.phr_drugs.find_by_id(known_drug.id)
    assert(updated_rec.drug_strength_form_C.blank?)
    assert(updated_rec.drug_strength_form.blank?)

    # Change both the coded value and the non-coded value.  The non-coded
    # value should win.
    update_data[:phr][:alt_drug_strength_form] = 'three'
    update_data[:phr][:drug_strength_form_C] = strength_code
    put :update, update_data, session_data
    assert_redirected_to :controller=>'phr_drugs', :action=>:index
    updated_rec = @profile.phr_drugs.find_by_id(known_drug.id)
    assert(updated_rec.drug_strength_form_C.blank?)
    assert_equal('three', updated_rec.drug_strength_form)

    # Try an unknown drug
    unknown_drug = PhrDrug.create!(:profile_id=>@profile.id, :latest=>1,
      :name_and_route_C=>'', :name_and_route=>'new drug',
      :drug_use_status_C=>'DRG-A')

    # Update the strength field
    update_data = {:phr=>{:instructions=>'hi',
      :name_and_route=>unknown_drug.name_and_route,
      :drug_use_status_C=>'DRG-A',
      :alt_drug_strength_form=>'one'},
      :id=>unknown_drug.id, :phr_record_id=>@profile.id_shown}
    put :update, update_data, session_data
    assert_redirected_to :controller=>'phr_drugs', :action=>:index
    updated_rec = @profile.phr_drugs.find_by_id(unknown_drug.id)
    assert(updated_rec.drug_strength_form_C.blank?)
    assert_equal('one', updated_rec.drug_strength_form)
    assert_equal('hi', updated_rec.instructions)

    # Update something else, and confirm the strength does not get lost
    update_data[:phr][:instructions] = 'two'
    put :update, update_data, session_data
    assert_redirected_to :controller=>'phr_drugs', :action=>:index
    updated_rec = @profile.phr_drugs.find_by_id(unknown_drug.id)
    assert(updated_rec.drug_strength_form_C.blank?)
    assert_equal('one', updated_rec.drug_strength_form)
    assert_equal('two', updated_rec.instructions)

    # Test what happens when a coded value previously in the list is no
    # longer in the list.  If the user saved it that way, then the value
    # should appear on the edit page, and when they update the record,
    # the value should remain the saved value.
    # Here we create a drug with a "why stopped" value that has an unknown code.
    known_drug2 = PhrDrug.create!(:profile_id=>@profile.id, :latest=>1,
      :name_and_route_C=>'27675', :drug_use_status_C=>'DRG-I')
    # Now set the why_stopped values without running through validation
    # (so we can store something not in the list).
    known_drug2.why_stopped = 'Other reason'
    known_drug2.why_stopped_C = 'ZZZ'
    known_drug2.save(:validate=>false)
    # Make sure that worked before continuing
    updated_rec = @profile.phr_drugs.find_by_id(known_drug2.id)
    assert_equal 'ZZZ', updated_rec.why_stopped_C
    assert_equal 'Other reason', updated_rec.why_stopped
    # Get the edit page and make sure the values are there
    get :edit, {:id=>known_drug2.id, :phr_record_id=>@profile.id_shown}, session_data
    assert_response :success
    assert response.body.index('value="ZZZ"')
    assert response.body.index('Other reason')
    # Now try to update the drug.
    update_data2 = update_data.dup
    update_data2[:phr] = update_data2[:phr].dup
    update_data2[:id] = known_drug2.id
    update_data2[:phr][:drug_use_status_C] = 'DRG-I'
    update_data2[:phr][:why_stopped] = 'Other reason'
    update_data2[:phr][:why_stopped_C] = 'ZZZ'
    update_data2[:phr][:instructions] = 'very important'
    put :update, update_data2, session_data
    assert_redirected_to :controller=>'phr_drugs', :action=>:index
    updated_rec = @profile.phr_drugs.find_by_id(known_drug2.id)
    assert_equal 'very important', updated_rec.instructions
    assert_equal 'ZZZ', updated_rec.why_stopped_C
    assert_equal 'Other reason', updated_rec.why_stopped
  end
end