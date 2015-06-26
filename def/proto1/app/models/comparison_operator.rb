class ComparisonOperator < ActiveRecord::Base
  has_and_belongs_to_many :predefined_fields
  extend HasShortList

  # Input field types used by get_input_field_type to indicate whether or
  # not the comparison operator shown can be used with a date, a list, or should
  # just have a plain text input type.  If the user chooses the 'begins with',
  # 'ends with', 'contains' or 'does not contain' operator on the fetch rule
  # form, the value field should not present a list, even though a list may
  # be valid for the 'equal' or 'not equal' operators.
  # These constants should match (be the negative versions of) the constants in
  # combo_fields_helper.rb and combo_fields.js
  PLAIN_TEXT_TYPE = -1
  LIST_TYPE = -2
  DATE_TYPE = -4

  # Determines what type of input field should be used for the operator chosen.
  # See note about the input field type constants above.
  def get_input_field_type
    rtn = PLAIN_TEXT_TYPE
    predefined_fields.each do |pf|
      case pf.field_type
      when 'CWE - coded with exceptions', 'CNE - coded with no exceptions',
           'Set - String'
        rtn = LIST_TYPE
      when 'DT - date', 'DTM - date/time'
        rtn = DATE_TYPE
      end
    end
    return rtn
  end # get_input_field_type
end
