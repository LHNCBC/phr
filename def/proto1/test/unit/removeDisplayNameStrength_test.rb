# A test class for the removeDisplayNameStrength.rb script.
#
# To run this test, just run it as you would a ruby script ("ruby ...").
require 'test_helper'

#require 'test/unit'
require 'open3'
require 'tempfile'
require 'rubygems'
#require 'ruby-debug'

class RemoveDisplayNameStrengthTest < ActiveSupport::TestCase
  # The tests below will write some test data to a file, run the script
  # on the file, and check the STDOUT and STDERR ouput from the script's 
  # process.  We will define each set of test data, STDOUT output, and STDERR
  # output as a three element array, and hold all of these arrays in a
  # containing array so the test code can be written simply.
  
  TEST_DATA = []
  
  # Confirm that two names with one strength value that matches the strength
  # field get collapsed into the same name.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_1
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20 (Oral-pill)|Oral-pill|Caps|20 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40 (Oral-pill)|Oral-pill|Caps|40 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
END_TEST_1

  test_case_data[1] = <<-EXPECTED_STDOUT_1
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL (Oral-pill)|Oral-pill|Caps|20 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL (Oral-pill)|Oral-pill|Caps|40 MG|||
EXPECTED_STDOUT_1

  test_case_data[2] = <<-EXPECTED_STDERR_1
Changing LESCOL 20 (Oral-pill) to LESCOL (Oral-pill) (form|strength = Caps|20 MG)
Changing LESCOL 40 (Oral-pill) to LESCOL (Oral-pill) (form|strength = Caps|40 MG)
EXPECTED_STDERR_1

  # Confirm that two names are not changed if the strength value in one of the
  # names does not match the strength values in the strength field.  (Changing
  # the order of the lines does not count as a change, for our purposes.)
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_2
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20 (Oral-pill)|Oral-pill|Caps|20 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40 (Oral-pill)|Oral-pill|Caps|41 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
END_TEST_2

  test_case_data[1] = <<-EXPECTED_STDOUT_2
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20 (Oral-pill)|Oral-pill|Caps|20 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40 (Oral-pill)|Oral-pill|Caps|41 MG|||
EXPECTED_STDOUT_2

  test_case_data[2] = ''

  
  # Confirm that the strength field can contain an additional number if
  # there are two values in the strength field.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_3
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20 (Oral-pill)|Oral-pill|Caps|20-80 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40 (Oral-pill)|Oral-pill|Caps|40-80 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
END_TEST_3

  test_case_data[1] = <<-EXPECTED_STDOUT_3
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL (Oral-pill)|Oral-pill|Caps|20-80 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL (Oral-pill)|Oral-pill|Caps|40-80 MG|||
EXPECTED_STDOUT_3

  test_case_data[2] = <<-EXPECTED_STDERR_3
Changing LESCOL 20 (Oral-pill) to LESCOL (Oral-pill) (form|strength = Caps|20-80 MG)
Changing LESCOL 40 (Oral-pill) to LESCOL (Oral-pill) (form|strength = Caps|40-80 MG)
EXPECTED_STDERR_3


  # Confirm that any number of strength field values can be present; it only
  # matters that the display name contain all of the values in the strength
  # field. Also check the different strength value separators (for the display
  # name) and check that the order of the strength values does not matter.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_4
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20/80/90 (Oral-pill)|Oral-pill|Caps|20-80-90 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 90-40-80 (Oral-pill)|Oral-pill|Caps|40-80-90 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
END_TEST_4

  test_case_data[1] = <<-EXPECTED_STDOUT_4
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL (Oral-pill)|Oral-pill|Caps|20-80-90 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL (Oral-pill)|Oral-pill|Caps|40-80-90 MG|||
EXPECTED_STDOUT_4

  test_case_data[2] = <<-EXPECTED_STDERR_4
Changing LESCOL 20/80/90 (Oral-pill) to LESCOL (Oral-pill) (form|strength = Caps|20-80-90 MG)
Changing LESCOL 90-40-80 (Oral-pill) to LESCOL (Oral-pill) (form|strength = Caps|40-80-90 MG)
EXPECTED_STDERR_4


  # Confirm that the if the display name has "units" of -WASH, no change is
  # made.  Also, if there are multiple drugs listed (as indicated by a /,
  # "WITH", or " + ", or if the number is
  # followed by "HOUR" (i.e. not a strength), no change should be made.
  # (Trying to remove multiple strength values from multiple ingredients is
  # something we could try, but we aren't doing that currently.)
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_5
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20-WASH (Oral-pill)|Oral-pill|Caps|20 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40-WASH (Oral-pill)|Oral-pill|Caps|40 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
205442|350716|SBD|12 HR Brompheniramine 12 MG / Phenylpropanolamine 75 MG Extended Release Tablet [Family 12 Hour Antihistamine/Decongestant]|Extended Release Tablet|12 HR Brompheniramine 12 MG / Phenylpropanolamine 75 MG Extended Release Tablet|FAMILY 12 HOUR ANTIHISTAMINE|FAMILY 12 HOUR ANTIHISTAMINE XR (Oral-pill)|Oral-pill|12 Hrs XR Tabs|12-75 MG|||
687657|665063|SBD|Calcium Carbonate 600 MG / Vitamin D 400 UNT Oral Tablet [Caltrate 600 + Vitamin D]|Oral Tablet|Calcium Carbonate 600 MG / Vitamin D 400 UNT Oral Tablet|CALTRATE 600 + VITAMIN D|CALTRATE 600 + VITAMIN D (Oral-pill)|Oral-pill|Tabs|600-400 VAR UNITS|||TRUE
351787|308882|SBD|Calcium Carbonate 600 MG / Vitamin D 200 UNT Oral Tablet [Caltrate 600 with D Plus Soy]|Oral Tablet|Calcium Carbonate 600 MG / Vitamin D 200 UNT Oral Tablet|CALTRATE 600 WITH D PLUS SOY|CALTRATE 600 WITH D PLUS SOY (Oral-pill)|Oral-pill|Tabs|600 VAR UNITS|||TRUE
603195|343037|SBD|Guaifenesin 600 MG / Phenylephrine 20 MG Extended Release Tablet [GFN 600/Phenylephrine 20]|Extended Release Tablet|Guaifenesin 600 MG / Phenylephrine 20 MG Extended Release Tablet|GFN 600/PHENYLEPHRINE 20|GFN 600/PHENYLEPHRINE 20 XR (Oral-pill)|Oral-pill|XR Tabs|600-20 MG|||
849594|351273|SBD|Glipizide 2.5 MG / Metformin 500 MG Oral Tablet [Metaglip 2.5 MG/500 MG]|Oral Tablet|Glipizide 2.5 MG / Metformin 500 MG Oral Tablet|METAGLIP 2.5 MG/500 MG|METAGLIP 2.5 MG/500 MG (Oral-pill)|Oral-pill|Tabs|2.5-500 mg|||
END_TEST_5

  test_case_data[1] = <<-EXPECTED_STDOUT_5
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20-WASH (Oral-pill)|Oral-pill|Caps|20 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40-WASH (Oral-pill)|Oral-pill|Caps|40 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
205442|350716|SBD|12 HR Brompheniramine 12 MG / Phenylpropanolamine 75 MG Extended Release Tablet [Family 12 Hour Antihistamine/Decongestant]|Extended Release Tablet|12 HR Brompheniramine 12 MG / Phenylpropanolamine 75 MG Extended Release Tablet|FAMILY 12 HOUR ANTIHISTAMINE|FAMILY 12 HOUR ANTIHISTAMINE XR (Oral-pill)|Oral-pill|12 Hrs XR Tabs|12-75 MG|||
687657|665063|SBD|Calcium Carbonate 600 MG / Vitamin D 400 UNT Oral Tablet [Caltrate 600 + Vitamin D]|Oral Tablet|Calcium Carbonate 600 MG / Vitamin D 400 UNT Oral Tablet|CALTRATE 600 + VITAMIN D|CALTRATE 600 + VITAMIN D (Oral-pill)|Oral-pill|Tabs|600-400 VAR UNITS|||TRUE
351787|308882|SBD|Calcium Carbonate 600 MG / Vitamin D 200 UNT Oral Tablet [Caltrate 600 with D Plus Soy]|Oral Tablet|Calcium Carbonate 600 MG / Vitamin D 200 UNT Oral Tablet|CALTRATE 600 WITH D PLUS SOY|CALTRATE 600 WITH D PLUS SOY (Oral-pill)|Oral-pill|Tabs|600 VAR UNITS|||TRUE
603195|343037|SBD|Guaifenesin 600 MG / Phenylephrine 20 MG Extended Release Tablet [GFN 600/Phenylephrine 20]|Extended Release Tablet|Guaifenesin 600 MG / Phenylephrine 20 MG Extended Release Tablet|GFN 600/PHENYLEPHRINE 20|GFN 600/PHENYLEPHRINE 20 XR (Oral-pill)|Oral-pill|XR Tabs|600-20 MG|||
849594|351273|SBD|Glipizide 2.5 MG / Metformin 500 MG Oral Tablet [Metaglip 2.5 MG/500 MG]|Oral Tablet|Glipizide 2.5 MG / Metformin 500 MG Oral Tablet|METAGLIP 2.5 MG/500 MG|METAGLIP 2.5 MG/500 MG (Oral-pill)|Oral-pill|Tabs|2.5-500 mg|||
EXPECTED_STDOUT_5

  test_case_data[2] = ''


  # Confirm that units are okay (i.e., do not prevent the change).
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_6
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20-MG (Oral-pill)|Oral-pill|Caps|20 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40-MG (Oral-pill)|Oral-pill|Caps|40 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
END_TEST_6

  test_case_data[1] = <<-EXPECTED_STDOUT_6
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL (Oral-pill)|Oral-pill|Caps|20 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL (Oral-pill)|Oral-pill|Caps|40 MG|||
EXPECTED_STDOUT_6

  test_case_data[2] = <<-EXPECTED_STDERR_6
Changing LESCOL 20-MG (Oral-pill) to LESCOL (Oral-pill) (form|strength = Caps|20 MG)
Changing LESCOL 40-MG (Oral-pill) to LESCOL (Oral-pill) (form|strength = Caps|40 MG)
EXPECTED_STDERR_6


  # Confirm that if the change being made is known to be okay, no
  # message about the change is output.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_7
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|CEMILL 1000 (Oral-pill)|Oral-pill|Caps|1000 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|CEMILL 500 (Oral-pill)|Oral-pill|Caps|500 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
END_TEST_7

  test_case_data[1] = <<-EXPECTED_STDOUT_7
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|CEMILL (Oral-pill)|Oral-pill|Caps|1000 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|CEMILL (Oral-pill)|Oral-pill|Caps|500 MG|||
EXPECTED_STDOUT_7

  test_case_data[2] = ''

  
  # Confirm that for known okay changes, the full set of changes must be
  # present (we can't just do some of them without a review).  Here the test
  # data is the same as above, but one line is missing.  In this case, the
  # present line should still get processed, but a message about the change
  # should be output.
  # Change of plan:  Because of retired records, we now allow this.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] =  <<-END_TEST_8
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|CEMILL 1000 (Oral-pill)|Oral-pill|Caps|1000 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
END_TEST_8

  test_case_data[1] = <<-EXPECTED_STDOUT_8
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|CEMILL (Oral-pill)|Oral-pill|Caps|1000 MG|||
EXPECTED_STDOUT_8

  test_case_data[2] = ''

  
  # Confirm that for known okay changes, no more than that set of changes can
  # present (we can't add more of them without a review).  Here the test
  # data is the same as #7, but with one new line.  In this case, the
  # set should still get processed, but a message about the change
  # should be output.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_9
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|CEMILL 1000 (Oral-pill)|Oral-pill|Caps|1000 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|CEMILL 500 (Oral-pill)|Oral-pill|Caps|500 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|CEMILL 750 (Oral-pill)|Oral-pill|Caps|750 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
END_TEST_9

  test_case_data[1] = <<-EXPECTED_STDOUT_9
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|CEMILL (Oral-pill)|Oral-pill|Caps|1000 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|CEMILL (Oral-pill)|Oral-pill|Caps|500 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|CEMILL (Oral-pill)|Oral-pill|Caps|750 MG|||
EXPECTED_STDOUT_9

  test_case_data[2] = <<-EXPECTED_STDERR_9
Changing CEMILL 1000 (Oral-pill) to CEMILL (Oral-pill) (form|strength = Caps|1000 MG)
Changing CEMILL 500 (Oral-pill) to CEMILL (Oral-pill) (form|strength = Caps|500 MG)
Changing CEMILL 750 (Oral-pill) to CEMILL (Oral-pill) (form|strength = Caps|750 MG)
EXPECTED_STDERR_9



  # Confirm that all display name values must be found in the strength list.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_10
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20-80-100 (Oral-pill)|Oral-pill|Caps|20-80 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40-80-100 (Oral-pill)|Oral-pill|Caps|40-80 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
END_TEST_10

  test_case_data[1] = <<-EXPECTED_STDOUT_10
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20-80-100 (Oral-pill)|Oral-pill|Caps|20-80 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40-80-100 (Oral-pill)|Oral-pill|Caps|40-80 MG|||
EXPECTED_STDOUT_10

  test_case_data[2] = ''


  # Confirm that no change is made if the strengths in one of the display
  # names is a subset of the strength field values in more than one
  # line of the set under consideration.  (This would lead to ambiguous
  # strength lists for the drug.)  In this case, "40" appears in both lines, so
  # we don't remove the strength from the display names.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_11
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20 (Oral-pill)|Oral-pill|Caps|20-40 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40 (Oral-pill)|Oral-pill|Caps|40-80 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
END_TEST_11

  test_case_data[1] = <<-EXPECTED_STDOUT_11
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20 (Oral-pill)|Oral-pill|Caps|20-40 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40 (Oral-pill)|Oral-pill|Caps|40-80 MG|||
EXPECTED_STDOUT_11

  test_case_data[2] = ''
  
  # Confirm that names are not changed if the strength value in one of the
  # names does not match the strength values in the strength field, even if
  # it does match a strength field value in another line in the set.  (This
  # similar to test 2, but here we are putting the "40" into the other line.)
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_12
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20 (Oral-pill)|Oral-pill|Caps|20-40 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40 (Oral-pill)|Oral-pill|Caps|41-60 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
END_TEST_12

  test_case_data[1] = <<-EXPECTED_STDOUT_12
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20 (Oral-pill)|Oral-pill|Caps|20-40 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40 (Oral-pill)|Oral-pill|Caps|41-60 MG|||
EXPECTED_STDOUT_12

  test_case_data[2] = ''

  
  # Confirm that if there is another word after the units, that is retained
  # and does not interfere with the removal of the strength.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_13
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20 CHEWABLE (Oral-pill)|Oral-pill|Caps|20 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40 XR EC (Oral-pill)|Oral-pill|Caps|40 MG|||
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
END_TEST_13

  # Note the test output reverses the order of the fluvastatin lines.  This
  # is just has to do with the hashing of the revised names; it is not relevant
  # for the test.
  test_case_data[1] = <<-EXPECTED_STDOUT_13
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103924|250637|SBD|Cetirizine 1 MG/ML Oral Solution [Zyrtec]|Oral Solution|Cetirizine 1 MG/ML Oral Solution|ZYRTEC|ZYRTEC (Oral-liquid)|Oral-liquid|Sol|5 MG/5ML|||
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL CHEWABLE (Oral-pill)|Oral-pill|Caps|20 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL XR EC (Oral-pill)|Oral-pill|Caps|40 MG|||
EXPECTED_STDOUT_13

  test_case_data[2] = <<-EXPECTED_STDERR_13
Changing LESCOL 20 CHEWABLE (Oral-pill) to LESCOL CHEWABLE (Oral-pill) (form|strength = Caps|20 MG)
Changing LESCOL 40 XR EC (Oral-pill) to LESCOL XR EC (Oral-pill) (form|strength = Caps|40 MG)
EXPECTED_STDERR_13
  

  # Confirm that a name in the DO_NOT_CHANGE list does not get revised.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_14
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
847254|847252|SBD|3 ML Insulin Lispro 25 UNT/ML / Insulin, Protamine Lispro, Human 75 UNT/ML Prefilled Syringe [Humalog Mix 75/25]|Prefilled Syringe|3 ML Insulin Lispro 25 UNT/ML / Insulin, Protamine Lispro, Human 75 UNT/ML Prefilled Syringe|HUMALOG MIX 75/25|HUMALOG MIX 75/25 (Injectable)|Injectable|Prefilled Syringe 3 ml|25-75 unt/ml|||
END_TEST_14

  test_case_data[1] = <<-EXPECTED_STDOUT_14
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
847254|847252|SBD|3 ML Insulin Lispro 25 UNT/ML / Insulin, Protamine Lispro, Human 75 UNT/ML Prefilled Syringe [Humalog Mix 75/25]|Prefilled Syringe|3 ML Insulin Lispro 25 UNT/ML / Insulin, Protamine Lispro, Human 75 UNT/ML Prefilled Syringe|HUMALOG MIX 75/25|HUMALOG MIX 75/25 (Injectable)|Injectable|Prefilled Syringe 3 ml|25-75 unt/ml|||
EXPECTED_STDOUT_14

  test_case_data[2] = ''


  # Confirm that two strength values do not prevent a change.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_15
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 10/10 (Oral-pill)|Oral-pill|Caps|10-10 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 5/10 (Oral-pill)|Oral-pill|Caps|5-10 MG|||
END_TEST_15

  test_case_data[1] = <<-EXPECTED_STDOUT_15
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL (Oral-pill)|Oral-pill|Caps|10-10 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL (Oral-pill)|Oral-pill|Caps|5-10 MG|||
EXPECTED_STDOUT_15

  test_case_data[2] = <<-EXPECTED_STDERR_15
Changing LESCOL 10/10 (Oral-pill) to LESCOL (Oral-pill) (form|strength = Caps|10-10 MG)
Changing LESCOL 5/10 (Oral-pill) to LESCOL (Oral-pill) (form|strength = Caps|5-10 MG)
EXPECTED_STDERR_15


  # Confirm that retired rows don't trip up the check for ambiguous strength
  # values.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_16
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
825195|349277|SBD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|PERKOCET 7.5/325 (Oral-pill)|Oral-pill|Tabs|325-7.5 mg|||TRUE
825196|349278|SBD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|PERKOCET 7.5/325 (Oral-pill)|Oral-pill|Tabs|325-7.5 mg|||
825200|349279|SBD|Acetaminophen 325 MG / Oxycodone 10 MG Oral Tablet [PERKOCET 10/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 10 MG Oral Tablet|PERKOCET 10/325|PERKOCET 10/325 (Oral-pill)|Oral-pill|Tabs|325-10 mg|||
END_TEST_16

  test_case_data[1] = <<-EXPECTED_STDOUT_16
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
825195|349277|SBD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|PERKOCET (Oral-pill)|Oral-pill|Tabs|325-7.5 mg|||TRUE
825196|349278|SBD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|PERKOCET (Oral-pill)|Oral-pill|Tabs|325-7.5 mg|||
825200|349279|SBD|Acetaminophen 325 MG / Oxycodone 10 MG Oral Tablet [PERKOCET 10/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 10 MG Oral Tablet|PERKOCET 10/325|PERKOCET (Oral-pill)|Oral-pill|Tabs|325-10 mg|||
EXPECTED_STDOUT_16

  test_case_data[2] = <<-EXPECTED_STDERR_16
Changing PERKOCET 7.5/325 (Oral-pill) to PERKOCET (Oral-pill) (form|strength = Tabs|325-7.5 mg)
Changing PERKOCET 7.5/325 (Oral-pill) to PERKOCET (Oral-pill) (form|strength = Tabs|325-7.5 mg)
Changing PERKOCET 10/325 (Oral-pill) to PERKOCET (Oral-pill) (form|strength = Tabs|325-10 mg)
EXPECTED_STDERR_16

  # Confirm that retired rows still must have strength values that match the
  # ones in the strength field in order to be changed.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_17
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
825195|349277|SBD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|PERKOCET 7.5/325 (Oral-pill)|Oral-pill|Tabs|425-7.5 mg|||TRUE
END_TEST_17

  test_case_data[1] = <<-EXPECTED_STDOUT_17
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
825195|349277|SBD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|PERKOCET 7.5/325 (Oral-pill)|Oral-pill|Tabs|425-7.5 mg|||TRUE
EXPECTED_STDOUT_17

  test_case_data[2] = ''

  # Test that two lines having the same strength values does not prevent
  # the name from being revised.  (Sometimes just the form is different, e.g.
  # Caps or Tabs.)
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_18
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
825195|349277|SBD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|PERKOCET 7.5/325 (Oral-pill)|Oral-pill|Caps|325-7.5 mg|||
825196|349278|SBD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|PERKOCET 7.5/325 (Oral-pill)|Oral-pill|Tabs|325-7.5 mg|||
END_TEST_18

  test_case_data[1] = <<-EXPECTED_STDOUT_18
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
825195|349277|SBD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|PERKOCET (Oral-pill)|Oral-pill|Caps|325-7.5 mg|||
825196|349278|SBD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|PERKOCET (Oral-pill)|Oral-pill|Tabs|325-7.5 mg|||
EXPECTED_STDOUT_18

  test_case_data[2] = <<-EXPECTED_STDERR_18
Changing PERKOCET 7.5/325 (Oral-pill) to PERKOCET (Oral-pill) (form|strength = Caps|325-7.5 mg)
Changing PERKOCET 7.5/325 (Oral-pill) to PERKOCET (Oral-pill) (form|strength = Tabs|325-7.5 mg)
EXPECTED_STDERR_18

  # Test a brand name will not get revised to the same name as a generic name.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_19
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
825195|349277|SCD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|Perkocet (Oral-pill)|Oral-pill|Caps|325-7.5 mg|||
825196|349278|SBD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|PERKOCET 7.5/325 (Oral-pill)|Oral-pill|Tabs|325-7.5 mg|||
END_TEST_19

  test_case_data[1] = <<-EXPECTED_STDOUT_19
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
825195|349277|SCD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|Perkocet (Oral-pill)|Oral-pill|Caps|325-7.5 mg|||
825196|349278|SBD|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet [PERKOCET 7.5/325]|Oral Tablet|Acetaminophen 325 MG / Oxycodone 7.5 MG Oral Tablet|PERKOCET 7.5/325|PERKOCET 7.5/325 (Oral-pill)|Oral-pill|Tabs|325-7.5 mg|||
EXPECTED_STDOUT_19

  test_case_data[2] = ''


  # Test that no change is made if the strength field has more than two
  # values and the display name field has fewer values than the strength field.
  test_case_data = []
  TEST_DATA << test_case_data
  test_case_data[0] = <<-END_TEST_20
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20 (Oral-pill)|Oral-pill|Caps|20-80-90 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40 (Oral-pill)|Oral-pill|Caps|40-80-90 MG|||
END_TEST_20

  test_case_data[1] = <<-EXPECTED_STDOUT_20
RXCUI|GENERIC_RXCUI|TTY|FULL_NAME|RXN_DOSE_FORM|FULL_GENERIC_NAME|BRAND_NAME|DISPLAY_NAME|ROUTE|NEW_DOSE_FORM|STRENGTH|SUPPRESS_FOR|DISPLAY_NAME_SYNONYM|IS_RETIRED
103918|310404|SBD|fluvastatin 20 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 20 MG Oral Capsule|LESCOL|LESCOL 20 (Oral-pill)|Oral-pill|Caps|20-80-90 MG|||
103919|310405|SBD|fluvastatin 40 MG Oral Capsule [Lescol]|Oral Capsule|fluvastatin 40 MG Oral Capsule|LESCOL|LESCOL 40 (Oral-pill)|Oral-pill|Caps|40-80-90 MG|||
EXPECTED_STDOUT_20

  test_case_data[2] = ''



  # This is the test method that runs the tests on the TEST_DATA array.
  def test_processing
    # Get the path to the script we're testing.
    script_pn = File.join(File.dirname(__FILE__), '..', '..', 'script',
                          'removeDisplayNameStrength.rb')
    # For each test case, run the script on the test data and collect
    # the STDOUT and STDERR data.
    TEST_DATA.each_with_index do |test_case_data, i|
      test_file = Tempfile.new('temp_test_data')
      test_file.puts(test_case_data[0])
      test_file.close
      out_lines = nil
      err_lines = nil
      cmd = "ruby #{script_pn} #{test_file.path} test_mode"
      Open3.popen3(cmd) do |stdin, stdout, stderr|
        out_lines = stdout.readlines.join
        err_lines = stderr.readlines.join
      end

      # The error output now contains some extra stuff we don't want to
      # bother checking.  (It is a reformatting of the information that was
      # already output.)
      if_index = err_lines.index('If')
      err_lines = err_lines[0, if_index] if if_index

      assert_equal(test_case_data[1], out_lines, "case \##{i+1}, stdout")
      assert_equal(test_case_data[2], err_lines, "case \##{i+1}, stderr")
    end
  end
end
