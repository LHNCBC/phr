# To change this template, choose Tools | Templates
# and open the template in the editor.

class Phr < ActiveRecord::Base
  include UserData
  extend UserData::ClassMethods

  validates_presence_of :pseudonym
  belongs_to :profile
  
  # Set up methods for accessing and working this model's lists
  # In the test environment, these lists might not exist, so we can't load them
  # immediately when the class is loaded, which is why we pass a proc.
  init_nonsearch_list :race, Proc.new{AnswerList.find_by_id(247).list_answers}, :code, :answer_text
  init_nonsearch_list :gender, Proc.new{TextList.find_by_list_name('Gender').text_list_items},
    :code, :item_text
  init_nonsearch_list :pregnant, Proc.new{TextList.find_by_list_name('YES_NO').text_list_items},
    :code, :item_text

  # A list of the fields that are dates
  DATE_FIELDS = ['birth_date', 'due_date']

  # When validating, convert the date to HL7 and epoch time.  Also check
  # gender_C, though for errors there we need to be careful with the message
  # because the gender_C field is not visible to the user.
  def validate
    # Validate if something has changed, or if it is a new record, validate
    # everything, because even if it hasn't been changed (i.e. left as nil)
    # it likely hasn't been validated yet.
    if new_record? || gender_C_changed?
      # Validate gender_C
      if gender_C.blank?
        errors.add(:gender, 'is a required field')
      else
        self.gender = self.class.gender_for_code(gender_C)
        if !gender
          errors.add(:gender, 'must match a list value')
        end
      end
    end

    # Validate race_C
    if new_record? || race_or_ethnicity_C_changed?
      if race_or_ethnicity_C.blank?
        self.race_or_ethnicity = ''
      else
        self.race_or_ethnicity = self.class.race_for_code(race_or_ethnicity_C)
        if !race_or_ethnicity
          errors.add(:race_or_ethnicity, 'must match a list value (if specified)')
        end      
      end
    end

    validate_cwe_field(:pregnant)
    
    # Validate the date fields
    date_reqs = self.class.date_requirements(['birth_date'], 'phr_home')
    validate_date('birth_date', date_reqs['birth_date'])
    date_reqs = self.class.date_requirements(['due_date'], 'phr')
    validate_date('due_date', date_reqs['due_date'])
    
    # Pseudonym must be unique (but strip whitespace first)
    pseudonym.strip! if pseudonym
    # For now just assume own user; otherwise we don't know which user's
    # profiles to check.
    other_names = Set.new
    if (!profile or !profile.users or profile.users.empty?)
      errors.add(:base, 'The PHR record is not associated with a user')
    else
      user_profs = profile.users[0].profiles
      user_profs.each {|p| other_names << p.phr.pseudonym unless !p.phr or p.phr.id==id}
      if other_names.member?(pseudonym)
        errors.add(:pseudonym, 'is already used by another record')
      end
    end
  end # validate


  # Provides a name/age/gender label array for the current phr.
  # Age may be abbreviated or spelled out and gender may be included
  # or omitted.
  #
  # Parameters:
  # * spell_out - flag indicating whether to spell out ("years old") or
  #   abbreviate ("y/o") the age information
  # * include_gender - flag indicating whether or not to include the gender
  #
  # Returns:
  # * an array containing;
  #   1) the name as the first element;
  #   2) the age string as the second element; and
  #   3) IF gender was requested, the gender as the third element.
  #
  def name_age_gender_label(spell_out, include_gender)

    label = []
    label[0] = pseudonym
    if birth_date.nil? 
      label[1] = 'no DOB on file'
    else
      label[1] = FormData.short_age(birth_date, Date.today, spell_out)
    end
    if !gender.nil? && include_gender
      label[2] = gender
    end
    return label
  end
end
