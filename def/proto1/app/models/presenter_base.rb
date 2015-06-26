# A base class for (some) presenter classes (mostly for basic mode pages, but
# that could change).
class PresenterBase
  attr_reader :form_obj # the form object name (e.g. 'fe')

  # Initializes a new instance
  #
  # Parameters:
  # * form_params - (optional) form parameters, e.g. from a post
  def initialize(form_params = {})
    form_params = {} if !form_params # might be nil
    init_class_vars
    @form_obj = FORM_OBJ_NAME
    @form_params = form_params
  end

  # Defines presenter attributes for the class and instance.  The instance
  # accessor is a pass-through to the class accessor, so that those values
  # can be accessed from the view.
  #
  # Parameters:
  # * attr_names - the names of the attributes to be defined (an array of
  #   symbols)
  def self.presenter_attrs(attr_names)
    attr_names.each do |var_name|
      # Define these on the class, but also create an accessor on the instances
      # for access from the view template.  Use instance variables on the class
      # instead of class variables which are shared amongst subclasses.
      instance_eval "class <<self; attr_accessor '#{var_name}'; end"
      define_method(var_name) {self.class.send(var_name)}
    end
  end

  presenter_attrs([:fds, :form]) # field descriptions and form accessors


  attr_reader :data # a DataRec instance, holding posted form data


  # A class that looks like a data record for the data on this form.  Field
  # names (including suffixes) can be sent to an instance as though there
  # were a method defined.
  class DataRec
    # For the validations stuff below.  From http://stackoverflow.com/a/938786/360782
    def save(validate = true)
      validate ? valid? : true
    end
    def save!(validate = true); raise 'error' if !save; end
    def new_record?; true; end

    # Include some stuff to support validation of date fields for forms
    # with data that doesn't go into models.  This is here so we can
    # use UserData.validate_date.
    include ActiveRecord::Validations
    include UserData
    extend UserData::ClassMethods

    # Initializes a new instance
    #
    # Parameters:
    # * form_params - (optional) form parameters, e.g. from a post.  Keys
    #   should be symbols
    def initialize(form_params={})
      # form_params might be nil, in which case we set it to {}
      @form_params = form_params ? form_params : {}
    end

    # Pretends the method is defined, and returns the form parameter value,
    # if any.  Also allows assignment of values via method calls.
    def method_missing(method_name, *args)
      method_s = method_name.to_s
      if method_s.last == '='
        @form_params[method_s.slice(0..-2).to_sym] = args[0]
      else
        rtn = @form_params[method_name]
      end
      return rtn
    end

    # Shows the contents of @form_params.
    def inspect; @form_params.inspect; end
  end


  # Initializes class variables
  #
  # Parameters:
  # * form_name - the name of the form for which field descriptions should be
  #   loaded
  def init_class_vars
    c = self.class
    if c.form.nil?
      # Store these as instance variables on the class
      # form_name defined in subclass
      c.form = Form.where(form_name: form_name).first 
      c.fds = {}
      fd_objs = c.form.field_descriptions.where(
        :target_field=>self.class.fields_used) # fields_used is defined in the subclass
      fd_objs.each {|fd| c.fds[fd.target_field] = fd}
    end
  end

  
  # A hash from profile attribute names to their values based on the input values
  # on the form
  def profile_data
    if !@profile_data
      # Generates non-qa related data hash including email, password etc.
      # For example:
      # { :email => "an@email.address",
      #    ... ,
      #   :password => "a_password_string"
      # }
      attrs= {}
      qa_property_name = :question_answers
      non_qa_property_names = 
        profile_attr_to_field_id_map.keys - [qa_property_name]
      non_qa_property_names.each do |property_name|
        attrs[property_name] = form_field_value(property_name)
      end
      
      # Generates question_answers data hash based on the 
      # profile_attr_to_field_id_map. 
      # 
      # For example from the following map:
      # {:question_answers =>{
      #     0 => [ [s_question_1_id, s_answer_1_id], 
      #            [s_question_2_id, s_answer_2_id] ]
      #    ,1 => [ [f_question_1_id, f_answer_1_id], 
      #            [f_question_2_id, f_answer_2_id] ]
      #  }}
      # to the following data hash:
      # {:question_answers =>{
      #     0 => [ [s_question_1_value, s_answer_1_value], 
      #            [s_question_2_value, s_answer_2_value] ]
      #    ,1 => [ [f_question_1_value, f_answer_1_value], 
      #            [f_question_2_value, f_answer_2_value] ]
      #  }}
      # 
      # where 1 is QuestionAnswer::FIXED_QUESTION
      #       0 is QuestionAnswer::USER_QUESTION
      rqas = {}
      profile_attr_to_field_id_map[qa_property_name].each do |qtype, qas |
        tmp = []
        qas.each do |qa|
          q_id, a_id = qa
          tmp << [ @form_params[q_id], @form_params[a_id] ]
        end
        rqas[qtype] = tmp
      end
      
      # merge both non-qa and qa data hashes
      attrs[qa_property_name] = rqas
      @profile_data= attrs
    end
    @profile_data
  end
  
  
  # Returns the value of the specified user property based on the information 
  # stored in @form_params
  # 
  # Parameters:
  # * user_property property of the user object. It has to be one of the keys in  
  # the profile_attr_to_field_id_map)
  def form_field_value(user_property)
    user_property = user_property.to_sym unless user_property.is_a? Symbol
    if profile_attr_to_field_id_map.keys.include?(user_property)
      id = profile_attr_to_field_id_map[user_property]
      @form_params[id]
    else
      raise "The user property [#{user_property}] does not exist" 
    end
  end
  
end
