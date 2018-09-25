class ClassificationController < ApplicationController
  before_action :admin_authorize
  before_action :show_header
  before_action :set_paper_trail_whodunnit

  helper FormHelper
  include FormHelper
  include ComboFieldsHelper
  include TextFieldsHelper

  # forms that are using records stored in class management system
  @@system_forms = %w(panel_edit)


  # Shows all subclasses and data_classes (AKA class items) of an input parent
  # class on an input form
  #
  # Parameters:
  # *params[:form_name] name of the form for displaying list of subclasses and
  # data_classes (AKA class items)
  # *params[:parent_id] ID of parent class
  # *params[:fe] form data received from a post request for deleting a subclass
  # or data_class (AKA class item)
  def show
    form_name = params[:form_name]
    parent_class = Classification.find_by_id(params[:parent_id])
    args = ["show"]
    @form_title = parent_class.build_title(*args).html_safe
    @page_errors = []
    if request.post?
      delete_classification_record(params[:fe], @page_errors)
      @@system_forms.each{|e| expire_form_cache(e)}
    end
    @data_hash = parent_class.get_data_hash(form_name, *args)
    @action_url = request.fullpath
    render_form(form_name)
  end


  # Shows the top level classes (AKA class types)
  def show_class_types
    params[:parent_id] = Classification::ROOT.id
    show
  end


  # Displays a form for creating a new class or a new class item
  #
  # Parameters:
  # *params[:form_name] name of the form showing an input field for creating or
  # editing a classification record
  # *params[:node_type] type of a node in classification system, e.g. either
  # class or class item
  # *params[:parent_id] ID of parent classification record
  # *params[:fe] form data received from a post request. It has information
  # about a classification record
  # *params[:fe][:cancel] a flag indicating whether the post request is submitted
  # by a cancel button or not
  def new
    form_name = params[:form_name]
    parent_class = Classification.find_by_id(params[:parent_id])
    args =["new", params[:node_type], parent_class.id]
    @form_title = parent_class.build_title(*args).html_safe

    if (request.post?) && !params[:fe][:cancel]
      @data_hash = data_hash_from_params(params[:fe], form_name)
      new_class = parent_class.save_classification(
                                 @data_hash[form_name], @page_errors, *args)
    end

    if new_class
      @@system_forms.each{|e| expire_form_cache(e)}
      redirect_to parent_class.show_classifications_path
    else
      @data_hash ||= parent_class.get_data_hash(form_name, *args)
      # Dynamically generates autoCompleter for class_item field
      if args[1] == Classification::CLASS_ITEM_NODE_TYPE
        list_desc, target = parent_class.list_description, "name"
        @data_hash[form_name] ||= {}
        @data_hash[form_name][target]=
          get_class_item_combo_spec(list_desc, form_name, target)
      end

      @data_hash.merge!("cancel" => parent_class.show_classifications_path)
      @action_url = request.fullpath
      render_form(form_name)
    end
  end


  # Displays a form for creating a new class type
  def new_class_type
    params[:parent_id] = Classification::ROOT.id
    new
  end


  # Edits a classification record
  #
  # Parameters:
  # *params[:form_name] name of the form showing an input field for creating or
  # editing a classification record
  # *params[:classification] name of a classification level, e.g. class_types,
  # class_names and class_items
  # *params[:id] ID of current classification record
  # *params[:fe] form data received from a post request. It has information
  # about a classification record
  # *params[:fe][:cancel] a flag indicating whether the post request is submitted
  # by a cancel button or not
  def edit
    form_name = params[:form_name]
    args = ["edit", params[:node_type], params[:id]]
    model = (args[1]==Classification::CLASS_NODE_TYPE) ? Classification : DataClass
    parent_class = model.find_by_id(args[2]).parent

    @form_title = parent_class.build_title(*args).html_safe
    @page_errors =[]

    if request.put? && !params[:fe][:cancel]
      @data_hash = data_hash_from_params(params[:fe], form_name)
      saved_record = parent_class.save_classification(
        @data_hash[form_name], @page_errors, *args)
    end

    if saved_record
      @@system_forms.each{|e| expire_form_cache(e)}
      redirect_to parent_class.show_classifications_path
    else
      @data_hash ||= parent_class.get_data_hash(form_name, *args)
      # Dynamically generates autoCompleter for class_item field
      if args[1] == Classification::CLASS_ITEM_NODE_TYPE
        list_desc, target = parent_class.list_description, "name"
        @data_hash[form_name] ||= {}
        this_val = @data_hash[form_name][target]
        @data_hash[form_name][target] =
          get_class_item_combo_spec(list_desc, form_name, target, this_val)
      end
      @form_submission_method = :put

      @data_hash.merge!("cancel" => parent_class.show_classifications_path)
      @action_url = request.fullpath
      render_form(form_name)
    end
  end # end of edit


  # Gets combo field spec for creating/editing a class items
  #
  # Parameters:
  # * list_field a list_description record used for building a combo field
  # * form_name name of the form which has the combo field
  # * target the target_field of the field description record for the combo
  #   field
  # * this_val the value of the combo field
  def get_class_item_combo_spec(list_field, form_name, target, this_val= "")
    mqv_combo_specs = get_combo_field_specs_by_list_desc(
      list_field,    # db_field with autoComp list information
      target,  # the form_field for autoComp list
      form_name      # the form which has the form_field
      )
    ['cmb_spec', this_val, {'responseText' => mqv_combo_specs}]
  end


  # Deletes a record from classification system
  #
  # Parameters:
  # * fe_data parsed data submitted by the form
  # * page_errors an array of page error messages
  def delete_classification_record(fe_data, page_errors)
    fe_data.each do |k, v|
      if (m = /\Adelete(_\d+)\z/.match(k))
        record_table_name, record_id = v.split("/") # v looks like "class_name/class_obj_id"
        model = record_table_name.classify.constantize
        record = model.find_by_id(record_id)
        record.destroy
        # if the destroy is not success, e.g. it has some subclasses
        # add errors messages into the page_errors
        if !record.errors.empty?
          page_errors.concat record.errors.full_messages
        end
        #break
      end
    end
  end

end
