# encoding: UTF-8
# above is a dark magic to change the ruby source file's encoding to UTF-8
# without it the default encoding is US-ASCII
# see http://blog.grayproductions.net/articles/ruby_19s_three_default_encodings

require 'test_helper'

class FormDataTest < ActiveSupport::TestCase
  fixtures :forms
  def test_find_template_field_values

    form_str = 'PHR for {phrs.pseudonym.upcase} short_age({phrs.birth_date}) ' +
               '{phrs.gender.downcase}'
    now = Time.now
    short_taffy = []
    short_taffy << {"phrs" => {"pregnant" => nil,
                               "race_or_ethnicity_C" => "UK",
                               "due_date_ET" => nil,
                               "birth_date_ET" => -1879963200000,
                               "pregnant_C" => nil,
                               "pseudonym" => "Hortense",
                               "due_date_HL7" => nil,
                               "birth_date_HL7" => "1910/06/06",
                               "gender" => "Female",
                               "birth_date" => now.years_ago(100).to_date.to_s,
                               "race_or_ethnicity" => "Unknown",
                               "gender_C" => "F",
                               "due_date" => nil} }

    short_taffy << {"phrs" => {"pregnant" => true,
                               "race_or_ethnicity_C" => "4",
                               "due_date_ET" => nil,
                               "birth_date_ET" => -1879963200000,
                               "pregnant_C" => nil,
                               "pseudonym" => "Joseph",
                               "due_date_HL7" => nil,
                               "birth_date_HL7" => '1910/06/06',
                               "gender" => "Male",
                               "birth_date" => now.months_ago(11).to_date.to_s,
                               "race_or_ethnicity" => "Hispanic or Latino",
                               "gender_C" => "M",
                               "due_date" => nil}}

    short_taffy << {"phrs" => {"pregnant" => true,
                               "race_or_ethnicity_C" => "4",
                               "due_date_ET" => nil,
                               "birth_date_ET" => -1879963200000,
                               "pseudonym" => nil,
                               "pregnant_C" => nil,
                               "due_date_HL7" => nil,
                               "birth_date_HL7" => '1910/06/06',
                               "gender" => "Male",
                               "birth_date" => now.months_ago(11).to_date.to_s,
                               "race_or_ethnicity" => "Hispanic or Latino",
                               "gender_C" => "M",
                               "due_date" => nil}}

    short_taffy << {"phrs" => {"pregnant" => true,
                               "race_or_ethnicity_C" => "4",
                               "due_date_ET" => nil,
                               "birth_date_ET" => -1879963200000,
                               "pregnant_C" => nil,
                               "pseudonym" => "Joseph",
                               "due_date_HL7" => nil,
                               "birth_date_HL7" => '1910/06/06',
                               "gender" => "Male",
                               "race_or_ethnicity" => "Hispanic or Latino",
                               "gender_C" => "M",
                               "due_date" => nil}}

    short_taffy << {"phrs" => {"pregnant" => true,
                               "race_or_ethnicity_C" => "4",
                               "due_date_ET" => nil,
                               "birth_date_ET" => -1879963200000,
                               "pregnant_C" => nil,
                               "pseudonym" => "Joseph",
                               "due_date_HL7" => nil,
                               "birth_date_HL7" => '1910/06/06',
                               "birth_date" => now.months_ago(11).to_date.to_s,
                               "race_or_ethnicity" => "Hispanic or Latino",
                               "gender_C" => "M",
                               "due_date" => nil}}

    hortense = FormData.find_template_field_values(form_str, short_taffy[0])
    assert_equal('PHR for HORTENSE 100 y/o female', hortense)
    joseph = FormData.find_template_field_values(form_str, short_taffy[1])
    assert_equal('PHR for JOSEPH 11 m/o male', joseph)
    no_name = FormData.find_template_field_values(form_str, short_taffy[2])
    assert_equal('PHR for 11 m/o male', no_name)
    no_birthdate = FormData.find_template_field_values(form_str, short_taffy[3])
    assert_equal('PHR for JOSEPH male', no_birthdate)
    no_gender = FormData.find_template_field_values(form_str, short_taffy[4])
    assert_equal('PHR for JOSEPH 11 m/o', no_gender)

  end # test_find_template_field_values


  def test_shortage
    now = Time.now
    assert_equal('100 y/o', FormData.short_age(100.year.ago.to_s))
    day_03012011 = Time.parse("2011-03-01")
    assert_equal('5 m/o', FormData.short_age(5.month.ago(day_03012011).to_s,
        day_03012011))
    assert_equal('3 w/o',FormData.short_age(3.week.ago.to_s))
    assert_equal('2 d/o',FormData.short_age(2.day.ago.to_s))
    assert_equal(' < 1 d/o',FormData.short_age(1.second.ago.to_s))
    assert_equal(' < 1 d/o',FormData.short_age("Thu, 18 Dec 1912 20:54:06 -0500",
        "Thu, 18 Dec 1912 22:54:07 -0500".to_date))
    assert_equal('', FormData.short_age(nil))
  end # test_short_age

  def test_unicode
    f = Form.create!(
      :form_name => 'English',
      :form_title => '中文'.force_encoding('UTF-8'),
      :form_description => 'España'.force_encoding('UTF-8'),
      :sub_title => 'ダウンロード達成記念'.force_encoding('UTF-8')
    )

    f1= Form.find(f.id)
    assert_equal('English', f1.form_name)
    assert_equal('中文', f1.form_title)
    assert_equal('España', f1.form_description)
    assert_equal('ダウンロード達成記念', f1.sub_title)

  end
  def test_mass_saving

    # setup testing data
    # Since mass assignments not allowed on user object, the record needs to be
    # created by asigning individual values to the fields.
    @user = User.create()
    @user.salt = Time.object_id.to_s + rand.to_s
    @user.name = "user#{Time.now.to_i}"
    @user.password = "Valid1password"
    @user.password_confirmation = "Valid1password"
    @user.pin = '1234'
    @user.birth_date = '1950/1/2'
    @user.email = 'iamanemail@address.com'
    @user.save!

    @profile = Profile.create()
    fd = FormData.new("phr")

    # expose the private method mass_saving for testing purpose
    def fd.test_mass_saving(user, mass_inserts={}, mass_deletes={}, mass_updates={}, mass_update_fields={})
      @mass_inserts = mass_inserts
      @mass_deletes = mass_deletes
      @mass_updates = mass_updates
      @mass_update_fields = mass_update_fields
      mass_saving(user)
    end

    new_obr = ObrOrder.create!(:test_date => '2011/1/11')
    original_count = ObxObservation.count
    new_record= ObxObservation.new({:obx5_value => "new value",:latest =>  true,
        :profile_id => @profile.id,
        :obr_order_id => new_obr.id})
    new_record2= ObxObservation.new({:obx5_value => "new value 2",:latest =>  true,
                                    :profile_id => @profile.id,
                                    :obr_order_id => new_obr.id})

    options ={"obx_observations" => [new_record, new_record2]}
    fd.test_mass_saving(@user, options)
    last_obx = ObxObservation.last
    assert_equal ObxObservation.count, original_count+2
    assert_equal last_obx.obx5_value, "new value 2"
    assert_equal last_obx.latest, true
    next_last = ObxObservation.find((last_obx.id-1))
    assert_equal next_last.obx5_value, "new value"
    assert_equal next_last.latest, true


    original_count = ObxObservation.count
    last_obx.obx5_value = "changed value"
    options={"obx_observations" => [last_obx]}
    update_fields = {"obx_observations" => Set.new(["obx5_value"])}

    fd.test_mass_saving(@user,{},{},options, update_fields)
    last_obx_updated = ObxObservation.find(last_obx.id)
    assert_equal ObxObservation.count, original_count
    assert_equal last_obx_updated.obx5_value, "changed value"
    assert_equal last_obx_updated.latest, true

    original_count = ObxObservation.count
    options={"obx_observations" => [last_obx_updated.id, next_last.id] }
    fd.test_mass_saving(@user, {}, options)
    assert_equal ObxObservation.count, original_count - 2

  end


  def test_xss_sanitize
    fd = FormData.new("phr")
    # Exposes private method xss_santize for testing
    def fd.test_xss_sanitize(a,b)
      xss_sanitize(a,b)
    end
    testing_list =  %w(< %3C  &lt  &lt;  &LT  &LT;
&#60  &#060  &#0060  &#00060  &#000060  &#0000060
&#60;  &#060;  &#0060;  &#00060;  &#000060;  &#0000060;
&#x3c  &#x03c  &#x003c  &#x0003c  &#x00003c  &#x000003c
&#x3c;  &#x03c;  &#x003c;  &#x0003c;  &#x00003c;  &#x000003c;
&#X3c  &#X03c  &#X003c  &#X0003c  &#X00003c  &#X000003c
&#X3c;  &#X03c;  &#X003c;  &#X0003c;  &#X00003c;  &#X000003c;
&#x3C  &#x03C  &#x003C  &#x0003C  &#x00003C  &#x000003C
&#x3C;  &#x03C;  &#x003C;  &#x0003C;  &#x00003C;  &#x000003C;
&#X3C  &#X03C  &#X003C  &#X0003C  &#X00003C  &#X000003C
&#X3C;  &#X03C;  &#X003C;  &#X0003C;  &#X00003C;  &#X000003C;
\x3c  \x3C  \u003c  \u003C)
    data_value = testing_list.join("a")
    data_type = :string
    actual = fd.test_xss_sanitize(data_value, data_type)
    expected = testing_list.join(" a")
    assert_equal actual, expected

    data_value = testing_list.join("=a")
    data_type = :string
    actual = fd.test_xss_sanitize(data_value, data_type)
    expected = data_value
    assert_equal actual, expected

    data_value = testing_list.join("<<<a")
    actual = fd.test_xss_sanitize(data_value, data_type)
    expected = testing_list.join(" < < < a")
    assert_equal actual, expected
  end

end # form_data_test
