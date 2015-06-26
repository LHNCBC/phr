# This is an application specific model class.  Avoid putting general framework
# code here.
class PhrCondition  < ActiveRecord::Base
  include UserData
  extend UserData::ClassMethods
  belongs_to :gopher_term, :foreign_key=>:problem_C, :primary_key=>:key_id
  belongs_to :profile
 # alias_attribute :code, :problem_C
  
  # Set up methods for accessing and working this model's lists
  # Status list
  init_nonsearch_list :present, # the field's name is "present"
    Proc.new{TextList.find_by_list_name('condition_status').text_list_items},
    :code, :item_text

  # A list of the fields that are dates
  DATE_FIELDS = %w{when_started cond_stop}

  # When validating, convert the dates to HL7 and epoch time.
  def validate
    validate_cne_field(:present)

    # Validate the condition name and code
    if problem_C_changed?
      condition_info = GopherTerm.find_by_key_id(problem_C)
      self.problem = condition_info.consumer_name
    elsif problem_changed?
      condition_info = GopherTerm.find_by_consumer_name(problem)
      condition_info = GopherTerm.find_by_primary_name(problem) if !condition_info
      self.problem_C = condition_info.key_id if condition_info
    end

    if problem.blank?
      errors.add(:problem, 'must not be blank')
    end
    
    date_reqs = self.class.date_requirements(DATE_FIELDS, 'phr')
    DATE_FIELDS.each {|f| validate_date(f, date_reqs[f])}
  end


  # Returns the codes of the condition's classes, concatenated with |, like
  # |12|32|, or nil if there are no condition class codes.
  def problem_classes_C
    gopher_term ? gopher_term.classification_codes : nil
  end


  # Returns the names of the condition's classes, concatenated with |, like
  # |a|b|, or nil if there are no classes assigned.
  def problem_classes
    gopher_term ? gopher_term.classification_names : nil
  end


  # Returns information for links about this condition.  If one link is found,
  # that will be the return value; otherwise the return value will be an array
  # where each element is a two-element array consisting of a URL and a label
  # for the URL.
  def info_link
    data = gopher_term.info_link_data if gopher_term
    if !data ||data.size == 0
      data = 'http://search.nlm.nih.gov/medlineplus/query?' +
             'MAX=500&SERVER1=server1&SERVER2=server2&' +
             'DISAMBIGUATION=true&FUNCTION=search&PARAMETER=' +
             URI.escape(problem)
    end
    return data
  end


  # Checks to see if this record is the same condition as other existing records.
  #
  # Returns:  the record name if there is a duplicate, or nil otherwise.
  def dup_check
    conditions = problem_C ? ['problem_C=?', problem_C] : ['problem=?', problem]
    if id
      conditions[0] += 'and id!=?'
      conditions << id
    end
    return profile.phr_conditions.where(conditions).count>0 ? problem : nil
  end
end
