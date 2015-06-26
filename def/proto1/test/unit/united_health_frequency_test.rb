require 'test_helper'

class UnitedHealthFrequencyTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "import_csv" do
    f = Tempfile.new('united_health_import_test')
    file_data =<<END_TESTDATA
RXCUI,RX_CT,TTY,Full Name,GENERIC_RXCUI
197555,3414,SCD,Danazol 200 MG Oral Capsule,
213231,3414,SBD,Danazol 200 MG Oral Capsule [Danocrine],197555
197556,807,SCD,Danazol 50 MG Oral Capsule,
213216,807,SBD,Danazol 50 MG Oral Capsule [Danocrine],197556
856652,796,SCD,Dantrolene Sodium 100 MG Oral Capsule,
856654,796,SBD,Dantrolene Sodium 100 MG Oral Capsule [Dantrium],856652
1856652,796,SCD,Fake 100 MG Oral Capsule,
1856654,796,SBD,Fake 100 MG Oral Capsule [Dantrium],856652
END_TESTDATA
    f.puts(file_data)
    f.close

    # Create the drug name route and drug strength form records for the
    # data above (except for the two Fake drugs, which we mean to not be there.
    dnr = DrugNameRoute.create!(:code=>'dnr_1', :text=>'Danazol')
    dnr.drug_strength_forms << DrugStrengthForm.create!(:rxcui=>197555)
    dnr.drug_strength_forms << DrugStrengthForm.create!(:rxcui=>197556)
    dnr = DrugNameRoute.create!(:code=>'dnr_2', :text=>'Danocrine')
    dnr.drug_strength_forms << DrugStrengthForm.create!(:rxcui=>213231)
    dnr.drug_strength_forms << DrugStrengthForm.create!(:rxcui=>213216)
    dnr = DrugNameRoute.create!(:code=>'dnr_3', :text=>'Dantrolene Sodium')
    dnr.drug_strength_forms << DrugStrengthForm.create!(:rxcui=>856652)
    dnr = DrugNameRoute.create!(:code=>'dnr_4', :text=>'Dantrium')
    dnr.drug_strength_forms << DrugStrengthForm.create!(:rxcui=>856654)

    UnitedHealthFrequency.delete_all
    UnitedHealthFrequency.import_csv(f.path)

    assert_equal(6, UnitedHealthFrequency.count)
    [197555, 213231, 197556, 213216].each do |rxcui|
      uhf = UnitedHealthFrequency.find_by_rxcui(rxcui)
      assert_equal(3414+807, uhf.display_name_count, "Error for RxCUI #{rxcui}")

    end
    [856652, 856654].each do |rxcui|
      uhf = UnitedHealthFrequency.find_by_rxcui(rxcui)
      assert_equal(796, uhf.display_name_count, "Error for RxCUI #{rxcui}")
    end

  end
end
