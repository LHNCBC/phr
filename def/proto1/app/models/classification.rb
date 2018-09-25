class Classification < ActiveRecord::Base
  extend HasShortList
  has_paper_trail

  validates_uniqueness_of :class_code, :scope=>[:class_type_id ]
  validates_uniqueness_of :class_name, :scope=>[:p_id]
  validates_uniqueness_of :sequence, :scope=>[:p_id]
  validates_presence_of :class_code
  validates_presence_of :class_name
  validates_presence_of :class_type_id

  has_many :data_classes, ->{order("sequence")}, dependent: :destroy# links to class items
  has_many :subclasses, ->{order("sequence")}, class_name: 'Classification', foreign_key: "p_id",
    dependent: :destroy
  belongs_to :parent, class_name: "Classification", foreign_key: "p_id"
  belongs_to :list_description
  belongs_to :class_type, class_name: 'Classification', foreign_key: "class_type_id"

  delegate :item_master_table, :item_name_field, :item_code_field,
    :list_master_table, :list_identifier, :to => :list_description

  # Root of the classification tree
  ROOT =  Classification.find_by_class_name("ROOT")

  # node type of a class node in classification system
  CLASS_NODE_TYPE = "class"

  # node type of a class item node in classification system
  CLASS_ITEM_NODE_TYPE = "class item"

  # Maximum length of class name being displayed
  CLASS_NAME_MAX_LEN = 30


  # Returns a new unique class code for a new subclass whose parent is specified
  # by the input parameter
  #
  # Parameters:
  # * parent the id of the parent class for the new subclass to be created.
  def self.generate_unique_class_code(parent_id)
    parent_field = Classification.find(parent_id)
    if parent_field.is_root
      search_field = "p_id"
      search_field_value = parent_field.id
    else
      search_field = "class_type_id"
      search_field_value = parent_field.class_type_id || parent_field.id
    end
    cond = ["#{search_field} = ?", search_field_value]

    max_seq = Classification.where(cond).maximum(:sequence) || 0
    number_of_trials = 100
    while(number_of_trials > 0)
      max_seq +=1
      number_of_trials -= 1
      if Classification.send("find_by_sequence_and_#{search_field}",
          max_seq, search_field_value).nil?
        number_of_trials = -1
      end
    end

    if number_of_trials == -1
      max_seq
    else
      raise "Cannot find a unique class code for #{search_field} "+
        "#{search_field_value} based on sequence value"
    end
  end

  # Used by get_list_items to obtain the Classification records
  # with the specified class_code.
  #
  # Parameters:
  # * class_code the class code for the Classifiction records.
  def self.get_named_list_items(class_code = nil)
    ctype = Classification.where(class_code: class_code).take
    Classification.where(class_type_id: ctype.id)
  end


  # We used to be able to define a "validate" method that would get called.
  # That now causes a problem, so I am renaming them to "validate_instance" and
  # registering that with the built-in "validate" method.
  validate :validate_instance
  def validate_instance
    # Class should have list source (except for the root class)
    if !is_root && list_description_id.blank?
      class_name_str = class_name.blank? ? "current class" : class_name
      errors.add(:base, "List source (i.e. List Field Name)"+
                         " for class #{class_name_str} is missing")
    end

    # List source should not be changed when it has class item(s)
    if changed.include?("list_description_id") &&  data_classes.size > 0 &&
       !list_description_id.blank?
      errors.add(:base,
        "Cannot modify list source (i.e. List Field Name)"+
        " because it's being used by some class item")
    end
  end

  def after_validation
    # For new record, if class code is not valid, show user the latest unique code
    # For existing record, if the class code isn't valid after being altered, show user the
    # latest unique code plus the original code
    class_code_err_msg = errors[:class_code]
    if !class_code_err_msg.nil?
      new_code = Classification.generate_unique_class_code(p_id)
      errors.add(:base,  " The new unique class code available is #{new_code}")
      if !new_record?
        ori_code = changes["class_code"][0]
        errors.add(:base, " The original class code is #{ori_code}.")
      end
    end
  end


  # This method searches the table for a record matching the given field data
  # (input_fields) and then returns data for the given output_fields.  The
  # return value is a hash from the output_field names to the value(s) for
  # the record that was found.
  #
  # This is intended to be called after the user has selected an item from an
  # autocompleter, when the program then needs to go back for additional
  # data about the selected item, but could be used with any table.
  #
  # IF YOU CHANGE this - specifically the parameters - please test it for
  # ALL table classes.  The problem is that other tables use the version of
  # this in active_record_extensions.rb.  If you change the signature and
  # then the call to this, it could bomb on other classes.  THANKS.  lm, 2/2008
  #
  # Parameters:
  # * input_fields - a hash from field names (column names) for this table
  #   to values.  Together the entries in input_fields should specify a
  #   particular record in the table.
  # * output_fields - an array of field names specifying the data to be
  #   returned.  These field names can be method names defined in the model
  #   class rather than column in the actual database table.
  # * list_name - the class_code of the top level class type record in this case
  def self.find_record_data(input_fields, output_fields, list_name)
    # The values in the input_fields, if strings, might be trimmed versions
    # of the values in the database table (i.e. the extra whitespace on the
    # left and right is removed).  To handle this, we'll need to trim values
    # that are strings.  SQL appears to allow you to trim any type of data,
    # so we'll just trim all the values and let the database decide whether it
    # is necessary.

    # typical parameter values for test panel classes
    # input_fields :  {class_code=>12}
    # output_fields : [get_sublist]
    # list_name : 'panel_class'

    class_code = input_fields['class_code']

    panel_class_type = Classification.where(['class_code=? and p_id=?',
         list_name, ROOT && ROOT.id]).first

    class_item = Classification.where(['p_id=? and class_code=?',
        panel_class_type.id, class_code]).first

    sub_class_items = Classification.where(['p_id=?', class_item.id]).order('sequence').load

    ret = {}
    name_array = []
    code_array = []
    # items belong to the class, without subclasses
    data_table = class_item.item_master_table
    name_col = class_item.item_name_field
    code_col = class_item.item_code_field
    tableClass = data_table.classify.constantize

    data_items = DataClass.where(['classification_id =?', class_item.id]).order('sequence').load

    data_items.each do |item|
      #item_id = item.item_id
      item_code = item.item_code # use code later
      data_table_item = tableClass.where(code_col=>item_code).first
      name_array << data_table_item.send(name_col)
      code_array << data_table_item.send(code_col)
    end

    # process sub classes as headings in the list
    id_to_heading = {}
    heading_sn = 1
    # items has sub classes
    sub_class_items.each do |sub_class|
      # For now, use the master table, name and code info defined in the
      # top level class record
#      data_table = sub_class.item_master_model
#      name_col = sub_class.item_name_field
#      code_col = sub_class.item_code_field
#      tableClass = data_table.constantize

      data_items = DataClass.where(['classification_id =?', sub_class.id]).order('sequence').load
      # add a heading if there's data in this sub class
      if data_items.length > 0
        name_array << sub_class.class_name
        heading_code = 'heading' + heading_sn.to_s
        code_array << heading_code
        data_items.each do |item|
          #item_id = item.item_id
          item_code = item.item_code # use code later
          data_table_item =  tableClass.where(code_col=>item_code).first
          name_array << data_table_item.send(name_col)
          code_array << data_table_item.send(code_col)
          id_to_heading[item_code] = heading_code
        end
      end
    end
    # options for creating headings in the list
    opts = {}
    opts['codes'] = code_array
    opts['itemToHeading'] = id_to_heading
    opts['suggestionMode']=0
    opts['autoFill']=true
    output_fields.each {|of| ret[of] = [name_array, code_array, opts]}

    return ret

  end


#  # an alternative way to access to the data
#  # NOT USED
#  def self.find_record_data_alt(input_fields, output_fields, list_name)
#    # The values in the input_fields, if strings, might be trimmed versions
#    # of the values in the database table (i.e. the extra whitespace on the
#    # left and right is removed).  To handle this, we'll need to trim values
#    # that are strings.  SQL appears to allow you to trim any type of data,
#    # so we'll just trim all the values and let the database decide whether it
#    # is necessary.
#
#    # typical parameter values for test panel classes
#    # input_fields :  {class_code=>12}
#    # output_fields : [get_sublist]
#    # list_name : 'panel_class'
#
#    class_code = input_fields['class_code']
#
#    panel_class_type = Classification.where(['class_code=? and p_id=?', list_name, ROOT && ROOT.id]).first
#
#
#    class_item = Classification.where(['p_id=? and class_code=?', panel_class_type.id,
#        class_code]).first
#
#    sub_class_items = Classification.where(['p_id=?', class_item.id]).order('class_name').load
#
#    ret = {}
#    name_array = []
#    code_array = []
#    # items belong to the class, without subclasses
#    data_items = DataClass.where(["classification_id =?", class_item.id]).order('sequence').load
#    data_items.each do |item|
#      data_table = item.data_item_type
#      name_col = item.name_method
#      code_col = item.code_method
#      item_id = item.data_item_id
#      tableClass = data_table.singularize.camelize.constantize
#      data_table_item = tableClass.find(item_id)
#      name_array << data_table_item.send(name_col)
#      code_array << data_table_item.send(code_col)
#    end
#
#    # process sub classes as headings in the list
#    id_to_heading = {}
#    heading_sn = 1
#    # items has sub classes
#    sub_class_items.each do |sub_class|
#      data_items = DataClass.where(["classification_id =?", sub_class.id]).order('sequence').load
#      # add a heading if there's data in this sub class
#      if data_items.length > 0
#        name_array << sub_class.class_name
#        heading_code = 'heading' + heading_sn.to_s
#        code_array << heading_code
#        data_items.each do |item|
#          data_table = item.data_item_type
#          name_col = item.name_method
#          code_col = item.code_method
#          item_id = item.data_item_id
#          tableClass = data_table.singularize.camelize.constantize
#          data_table_item = tableClass.find(item_id)
#          name_array << data_table_item.send(name_col)
#          item_code = data_table_item.send(code_col)
#          code_array << item_code
#          id_to_heading[item_code] = heading_code
#        end
#      end
#    end
#    # options for creating headings in the list
#    opts = {}
#    opts['codes'] = code_array
#    opts['itemToHeading'] = id_to_heading
#    opts['suggestionMode']=0
#    opts['autoFill']=true
#    output_fields.each {|of| ret[of] = [name_array, code_array, opts]}
#
#    return ret
#
#  end


  # Returns a hash containing data for showing and performing actions on the
  # input form
  #
  # Parameters:
  # * form_name name of the form for displaying subclasses and data_classes
  # * args is an array containing following elements:
  # 1) action the action to be performed on the form, e.g. show, new, edit
  # 2) node_type type of a node in the classification system
  # 3) record_id ID of the editing record
  def get_data_hash(form_name, *args)
    case args[0]
    when "show"
      get_data_hash_for_records(form_name)
    when "new", "edit"
      get_data_hash_for_record(form_name, *args)
    end
  end

  # Returns a hash containing subclasses and data_classes (AKA class items) in
  # order to be rendered on the input form
  #
  # Parameters:
  # * form_name name of the form for displaying subclasses and data_classes
  def get_data_hash_for_records(form_name)
      rtn = []
      get_list.each do |e|
        node_name, node_code, node_type, table_name, record_id, record = e
        el ={}
        # counts the number of elements in a class
        if node_type == CLASS_NODE_TYPE
          rec = Classification.find_by_id(record_id)
          no = rec.subclasses.size + rec.data_classes.size
          no = nil if no==0
        end
        el["name"] = node_name + (no.nil? ? "": "[#{no.to_s}]")
        el["name_C"] = node_code
        el["node_type"] = node_type
        el["delete"] = "#{table_name}/#{record_id}"
        el["edit"] = "../#{table_name}/#{record_id};edit"
        el["children"] =
          node_type == CLASS_NODE_TYPE ? "..#{record.show_classifications_path}" : ""
        el["sequence"] = record.sequence
        rtn << el
      end
      {form_name => rtn}
  end


  # Returns a hash containing data of a classification record for creating or
  # editing a class or a class item record
  #
  # Parameters:
  # * form_name name of the form to display the record data
  # * args is an array containing the following elements:
  # 1) action the action to be performed on the form, e.g. show, new, edit
  # 2) node_type type of a node in the classification system
  # 3) record_id ID of the editing record or ID of the parent record for the new record
  def get_data_hash_for_record(form_name, *args)
    action, node_type, record_id = args
    rtn={"node_type" => node_type, form_name => {}}
    case action
    when "new"
      # Generates a new unique class_code for the class type
      p = Classification.find(record_id)
      class_code = Classification.generate_unique_class_code(record_id)
      case node_type
      when CLASS_NODE_TYPE
        cl = Classification
        fid = "p_id"
      when CLASS_ITEM_NODE_TYPE
        cl = DataClass
        fid = "classification_id"
      end
      max_seq = cl.where(["#{fid} = ?", record_id]).maximum(:sequence)||0
      rtn[form_name] = {"name_C" => class_code, "sequence" => (max_seq+1)}
    when"edit"
      case node_type
      when CLASS_NODE_TYPE
        subclass = Classification.find(record_id)
        rtn[form_name] = {
          "name"=> subclass.class_name,
          "name_C" => subclass.class_code,
          "list_field" => subclass.list_description.display_name,
          "list_field_C" => subclass.list_description_id,
          "sequence" => subclass.sequence
          }
      when CLASS_ITEM_NODE_TYPE
        data_class = DataClass.find(record_id)
        item_code = data_class.item_code
        class_item = find_item(item_code)
        rtn[form_name] = {
          "name"=> class_item.send(item_name_field),
          "name_C" => item_code,
          "sequence" => data_class.sequence
          }
      end
    end
    rtn.merge("cancel" => show_classifications_path)
  end

  # Creates or updates a record in classification system and returns the record
  # if the saving succeed. Otherwise, add the error message into page_errors
  # array and returns false
  #
  # Parameters:
  # * data a hash containing a data for creating or editing a record
  # * page_errors an array of page error messages
  # * args an array contains the following elements:
  # 1) action an action to create or update a record, e.g. either 'new' or 'edit'
  # 2) node_type type of a node in the classification system
  # 3) record_id the record being edited
  def save_classification(data, page_errors, *args)
    action, node_type, record_id = args
    begin
      if data
        case node_type
        when CLASS_NODE_TYPE
          save_class(data, action, record_id)
        when CLASS_ITEM_NODE_TYPE
          save_class_item(data, action, record_id)
        else
          # do nothing
        end
      else
        raise "Classification data cannot be empty"
      end
    rescue Exception => e
      page_errors << e.message
      false
    end
  end


  # Creates or updates an DataClass record and returns the record if succeed.
  # Otherwise raise error using the save! method
  #
  # Parameters:
  # * data a hash containing a data for creating or editing a record
  # * action an action to create or update a record, e.g. either 'new' or 'edit'
  # * record_id the record being edited
  def save_class_item(data, action, record_id)
    item_code = data["name_C"]
    seq_no = data["sequence"]
    #class_item = find_item(item_code)
    case action
    when "edit"
      data_class = DataClass.find(record_id)
      #data_class.item_id = class_item.id
    when "new"
      data_class = data_classes.build
    else
      #do nothing
    end
    data_class.item_code = item_code
    data_class.sequence = seq_no
    data_class.save!
    data_class
  end



  # Creates or updates an Classification record and returns the record if succeed.
  # Otherwise raise error using the save! method
  #
  # Parameters:
  # * data a hash containing a data for creating or editing a record
  # * action an action to create or update a record, e.g. either 'new' or 'edit'
  # * record_id the record being edited
  def save_class(data, action, record_id)
    #data looks like {'name' => name_value}
    case action
    when "edit"
      subclass = Classification.find(record_id)
    when "new"
      subclass = Classification.new
      subclass.p_id = id
    else
      # do nothing
    end
    subclass.list_description_id = data["list_field_C"]
    subclass.class_name = data["name"]
    subclass.class_code = data["name_C"]
    subclass.sequence = data["sequence"]
    if subclass.parent.id == ROOT.id
      ct = ROOT.id
    elsif subclass.parent.class_type_id == ROOT.id
      ct = subclass.p_id
    else
      ct = subclass.parent.class_type_id
    end
    subclass.class_type_id = ct
    subclass.save!
    subclass
  end

   # Returns breadcrumb and page title based on different parent classes and
   # actions
   #
   # Parameters:
   # * args is an array of following elements:
   # 1) action the action to be performed on the form
   # 2) node_type type of the node in classification system
   # 3) record_id ID of a record in classification system (not used here)
   def build_title(*args)
    action, node_type, record_id=args
    p_rec_name = short_class_name
    last_link=page_title=link_list = nil
    case action
    when "show"
      #last_link = "Class Name:#{(p_rec_name)}"
      last_link = "#{(p_rec_name)}"
      page_title = "#{action.titleize} Classifications"
      link_list = parent && parent.build_uplink
    when "new", "edit"
      last_link = "#{action.titleize} #{node_type.titleize}"
      page_title = last_link
      link_list = build_uplink
    else# do nothing
    end
    link = link_list && link_list.join(" >")

    rtn = ""
    if !link.blank?
      link = link + " >#{last_link}"
      rtn = "<div class='classification_link'>#{link}</div>"
    end
    rtn += "<div class='classification_title'>#{page_title.titleize}</div>"
  end


  # Builds list of breadcrumb links from bottom up the classification tree
  def build_uplink
    p_name = short_class_name
    if p_name == "ROOT"
      breadcrumb =
        #"<span class='cls_name'>#{"class_types".titleize}</span>"
        "<span class='cls_name'>#{"top level classes".titleize}</span>"
      breadcrumb =
        "<a href='/class_types'>#{breadcrumb}</a>"
      rtn = [breadcrumb]
    else
      breadcrumb =
        "<span class='cls_name'>"+
        #"Class Name:#{(p_name).titleize}</span>"
        "#{(p_name).titleize}</span>"
      breadcrumb =
        "<a href='#{show_classifications_path}'"+
        "#{breadcrumb}</a>"
      rtn = [breadcrumb]

      if p_id
        rtn = parent.build_uplink.concat rtn
      end
    end
    rtn
  end


  # Finds the class item of the current class based on its code
  #
  # Parameters:
  # * item_code the code of a class or class item
  def find_item(item_code)
    cond_str = " #{item_code_field} like '#{item_code}' "
    if lm = list_master_table
      table_class = lm.classify.constantize
      table_class.get_list_items(list_identifier,nil,nil,cond_str)[0]
    else
      table_class = item_master_table.classify.constantize
      table_class.where(cond_str).first
    end
  end


  # Returns a list of classes and/or class items data which is an array with
  # five elements named as name, code, node type, table name, record id
  def get_list
    list = []
    if subclasses.size > 0
      table_name = subclasses.first.class.table_name
      subclasses.map do |e|
        list << [e.class_name, e.class_code, CLASS_NODE_TYPE, table_name, e.id, e]
      end
    end

    if list_description_id && !is_root
      if data_classes.size > 0
        name_field = item_name_field
        code_field = item_code_field

        table_name = data_classes.first.class.table_name
        data_classes.each do |dc|
          item_code = dc.item_code
          cond_str = " #{code_field} like '#{item_code}' "
          if lm = list_master_table
            table_class = lm.classify.constantize
            class_item =
              table_class.get_list_items(list_identifier,nil,nil,cond_str)[0]
          else
            table_class = item_master_table.classify.constantize
            class_item = table_class.where( cond_str).first
          end
          item_name = class_item.send(name_field)
          list << [item_name, item_code, CLASS_ITEM_NODE_TYPE, table_name, dc.id, dc]
        end
      end
    end
    list
  end


  # Returns the path for the page which displays class types or classification
  # records inside a class
  def show_classifications_path
    is_root ? "/class_types" : "/classifications/#{id};parent_id"
  end


  # Returns the truncated class name
  def short_class_name
    str = class_name
    max_length = CLASS_NAME_MAX_LEN
    str.length > max_length ?  str[0..max_length] + "..." : str
  end


  # Returns ture if this class is a root and vice versa
  def is_root
    !ROOT.nil? && ROOT.id == id
  end


  # This method could be used for generating a panel class spreadsheet -Frank
  # Prints and saves a classification tree of a class type
  #
  # Parameters:
  # * class_code class_code of a class type in the classification system
  # * indentation the indentation between parent and child node in the
  #   classification system
  # * file_name name of the file where the classification tree will be saved
  def self.print_and_save_class_tree(class_code, indentation=";",
      file_name="class_type")
    # find the class type
    root_id = Classification::ROOT.id
    c = Classification.find_by_class_code_and_p_id(class_code, root_id)
    # get rows for printing
    rtn = c.output_rows(indentation)
    file_name = [file_name,"_",Time.now.to_i,".txt"].join
    File.open(Rails.root + "/tmp/files/"+ file_name,"w") do |f|
      rtn.each {|e| puts e; f.puts e}
    end
    rtn
  end


  # Returns a list of rows properly indented as a classification tree below the
  # current class node
  #
  # Parameters:
  # * indentation the indentation between parent and child node in the
  #   classificaiton system
  # * number the number of indentations needed for the child nodes of this class
  def output_rows(indentation = ";", number = 1 )
    rtn= []
    get_list.each do |e|
      node_name, node_code, node_type, table_name, record_id, record = e
      el = []
      el << node_name
      el << node_code
      el << node_type
      rtn << (indentation * number) + el.join(" || ")
      if node_type == CLASS_NODE_TYPE
        rtn.concat record.output_rows(indentation,  number+1)
      end
    end
    rtn
  end

end
