module LoincPreparation

  def self.recreate_everything
    self.recreate_loinc_and_answer_list
    self.modify_loinc_and_answer_list
  end

  def self.recreate_loinc_and_answer_list
    puts "migrating loinc data"
    self.recreate_answer_list
    self.recreate_loinc

    # a dump file of 6 loinc related tables and data is at
    # /proj/defExtra/loinc_base_6_tables.sql
    # 53344 loinc_items total
  end

  def self.modify_loinc_and_answer_list
    self.remove_device_items
    self.loinc_items_special
    self.loinc_panels_special
    # need to be changed with a new list of selected panels and tests
    self.select_panels_for_phr

    # may not needed later
    self.additional_answer_list


    self.convert_screening_tests_to_panels

    self.include_a_panel

    self.create_risk_factor_panel
    
    # phr special
    self.phr_special_modification

    # enable some test panels
    self.add_new_panels

    self.remove_duplicated_units

    self.update_normal_ranges
    self.new_normal_range_and_units
    # additional ranges from a seperated spread sheet with 50% duplication
    # i.e. multiple range for same units
    self.addtional_normal_range_and_units

    # add scores for  score rules
    self.add_scores

    # panel/test classes
    self.update_panel_selection_and_classes

    # create a new table for included panles/tests names
    self.update_loinc_names_new

    puts "rebuilding ferret index for loinc_items"
    LoincItem.rebuild_index

    puts "rebuilding ferret index for loinc_names"
    LoincName.rebuild_index

  end

  def self.reload_loinc_and_answer_list
    DatabaseMethod.reloadDatabase("/proj/defExtra/loinc_base_6_tables.sql")
  end

  
  
  def self.recreate_loinc
    self.drop_loinc_tables
    self.create_loinc_tables
    self.copy_loinc_data
    self.copy_loinc_unit
    self.copy_form_data
    self.update_has_top_level_panel
  end
  
  def self.drop_loinc_tables
    ActiveRecord::Base.connection.drop_table :loinc_items
    ActiveRecord::Base.connection.drop_table :loinc_panels
    ActiveRecord::Base.connection.drop_table :loinc_units
    ActiveRecord::Base.connection.drop_table :loinc_names
  end
    
  def self.create_loinc_tables
    # loinc_items
    ActiveRecord::Base.connection.create_table :loinc_items do |t|
      t.column :loinc_num, :string, :limit=>7
      t.column :component, :string
      t.column :property, :string
      t.column :time_aspct, :string
      t.column :loinc_system, :string
      t.column :scale_typ, :string
      t.column :method_typ, :string
      t.column :shortname, :string
      t.column :long_common_name, :string
      t.column :datatype, :string
      t.column :relatednames2, :string, :limit=>4000
      t.column :related_names, :string
      t.column :base_name, :string
      t.column :unitsrequired, :string
      t.column :example_units, :string
      t.column :norm_range, :string
      t.column :loinc_class, :string
      t.column :common_tests, :string
      t.column :classtype, :integer
      t.column :status, :string
      t.column :map_to, :string
      t.column :answerlist_id, :integer
      t.column :loinc_version, :string, :limit=>10
      t.column :phr_display_name, :string
      t.column :consumer_name, :string
      t.column :help_url, :string
      t.column :help_text, :string
      t.column :hl7_v2_type, :string
      t.column :hl7_v3_type, :string
      t.column :curated_range_and_units, :string
      t.column :is_panel, :boolean, :default=>false
      t.column :has_top_level_panel, :boolean, :default=>false
      t.column :excluded_from_phr, :boolean, :default=>false
      t.column :included_in_phr, :boolean, :default=>false
      

    end
    # create index for loinc tables on loinc_num
    ActiveRecord::Base.connection.add_index "loinc_items", ["loinc_num"], :name => "loinc_items_loinc_num_index"

    # loinc_panels
    ActiveRecord::Base.connection.create_table :loinc_panels do |t|
      t.column :p_id, :integer
      t.column :loinc_item_id, :integer
      t.column :loinc_num, :string, :limit=>7
      t.column :sequence_num, :integer
      t.column :observation_required_in_panel, :string, :limit=>1
      t.column :answer_required, :boolean
      t.column :type_of_entry, :string, :limit=>1
      t.column :default_value, :string
      t.column :observation_required_in_phr, :string, :limit=>1
    end
    # create index for loinc tables on loinc_num
    ActiveRecord::Base.connection.add_index "loinc_panels", ["loinc_num"], :name => "loinc_panels_loinc_num_index"

    # loinc_uinits
    ActiveRecord::Base.connection.create_table :loinc_units do |t|
      t.column :loinc_item_id, :integer
      t.column :loinc_num, :string, :limit=>7
      t.column :unit, :string
      t.column :norm_range, :string
      t.column :norm_high, :string
      t.column :norm_low, :string
      t.column :danger_high, :string
      t.column :danger_low, :string
      t.column :source_type, :string
      t.column :source_id, :integer
    end
    # create index for loinc tables on loinc_num
    ActiveRecord::Base.connection.add_index "loinc_units", ["loinc_num"], :name => "loinc_units_loinc_num_index"

    # loinc names for selected panels/tests in phr
    ActiveRecord::Base.connection.create_table :loinc_names do |t|
      t.column :loinc_num, :string
      t.column :loinc_num_w_type, :string
      t.column :display_name, :string
      t.column :display_name_w_type, :string
      t.column :type_code, :integer
      t.column :type_name, :string
      t.column :component, :string
      t.column :short_name, :string
      t.column :long_common_name, :string
      t.column :related_names, :string
      t.column :consumer_name, :string
    end
    ActiveRecord::Base.connection.add_index "loinc_names", ["loinc_num"], :name => "loinc_names_loinc_num_index"
  end
    
  def self.copy_loinc_data
    # copy the loinc table
    loincs = LoincLoinc.all
    loincs.each do | loinc|
      LoincItem.create!(
        :loinc_num => loinc.LOINC_NUM,
        :component => loinc.COMPONENT,
        :property => loinc.PROPERTY,
        :time_aspct => loinc.TIME_ASPCT,
        :loinc_system => loinc.SYSTEM,
        :scale_typ => loinc.SCALE_TYP,
        :method_typ => loinc.METHOD_TYP,
        :shortname => loinc.SHORTNAME,
        :long_common_name => loinc.LONG_COMMON_NAME,
        :datatype => loinc.DATATYPE,
        :relatednames2 => loinc.RELATEDNAMES2,
        :unitsrequired => loinc.UNITSREQUIRED,
        :example_units => loinc.EXAMPLE_UNITS,
        :norm_range => loinc.NORM_RANGE,
        :loinc_class => loinc.CLASS,
        :common_tests => loinc.COMMON_TESTS,
        :answerlist_id => loinc.ANSWERLIST_ID,
        :is_panel => false,
        :loinc_version => '2.32',
        :excluded_from_phr => false,
        :hl7_v2_type => loinc.HL7_V2_DATATYPE,
        :hl7_v3_type => loinc.HL7_V3_DATATYPE,
        :consumer_name => loinc.CONSUMER_NAME,
        :included_in_phr => false,
        :curated_range_and_units => loinc.CURATED_RANGE_AND_UNITS,
        :has_top_level_panel => false,
        :status => loinc.STATUS,
        :map_to => loinc.MAP_TO,
        :classtype => loinc.CLASSTYPE,
        :base_name => loinc.BASE_NAME,
        :related_names => loinc.RELAT_NMS
      )
    end
    # update panel items
    LoincItem.update_all("is_panel=1", "loinc_class like '%PANEL%'")
  end
  
  def self.copy_loinc_unit
    loinc_units = LoincLoincUnit.all
    loinc_units.each do |unit|
      loinc_item = LoincItem.find_by_loinc_num(unit.LOINC_NUM)
      LoincUnit.create!(
        :loinc_item_id => loinc_item.id,
        :loinc_num => unit.LOINC_NUM,
        :unit => unit.UNIT,
        :norm_range => unit.NORMAL_RANGE,
        :source_type => unit.SOURCE_TYPE,
        :source_id => unit.SOURCE_ID
        )
    end
  end

  def self.drop_answer_tables
    ActiveRecord::Base.connection.drop_table :list_answers
    ActiveRecord::Base.connection.drop_table :answers
    ActiveRecord::Base.connection.drop_table :answer_lists
  end

  def self.create_answer_tables
    # answer_lists
    ActiveRecord::Base.connection.create_table :answer_lists do |t|
      t.column :list_name, :string
      t.column :list_desc, :string
      t.column :code_system, :string
      t.column :has_score, :boolean
    end

    # answers
    ActiveRecord::Base.connection.create_table :answers do |t|
      t.column :answer_text, :string
    end

    # list_answers
    ActiveRecord::Base.connection.create_table :list_answers do |t|
      t.column :answer_list_id, :integer
      t.column :answer_id, :integer
      t.column :code, :string
      t.column :sequence_num, :integer
      t.column :score, :integer
    end
  end

  def self.copy_answer_data
    sql_statement = "insert into answers(id, answer_text) select a.id, a.answer_string from loinc.ANSWER_STRING a;"
    ActiveRecord::Base.connection.execute(sql_statement)
    sql_statement = "insert into answer_lists(id, list_name, list_desc, code_system) select a.id, a.name, a.description, a.code_system from loinc.ANSWER_LIST a;"
    ActiveRecord::Base.connection.execute(sql_statement)
    sql_statement = "insert into list_answers(answer_list_id, answer_id, code, sequence_num) select a.answer_list_id, b.id, a.answer_code, a.sequence_no from loinc.ANSWER a, loinc.ANSWER_STRING b where b.answer_string = a.display_text;"
    ActiveRecord::Base.connection.execute(sql_statement)

    #  insert into answers(id, answer_text) select a.id, a.answer_string from loinc.ANSWER_STRING a;
    #  insert into answer_lists(id, list_name, list_desc, code_system) select a.id, a.name, a.description, a.code_system from loinc.ANSWER_LIST a;
    #  insert into list_answers(answer_list_id, answer_id, code, sequence_num) select a.answer_list_id, b.id, a.answer_code, a.sequence_no from loinc.ANSWER a, loinc.ANSWER_STRING b where b.answer_string = a.display_text;
  end
  
  def self.recreate_answer_list
    self.drop_answer_tables
    self.create_answer_tables
    self.copy_answer_data
  end
  
  # remove the 'device' loinc item
  def self.remove_device_items
    LoincItem.update_all("excluded_from_phr=1", "loinc_class like '%DEVICE%'" )

    # "DEVICES"
    # "PANEL.DEVICES"

  end
  # run copy_loinc_data first
  def self.copy_form_data
    
    #get all panels from loinc.loinc, 794 total
    panels = LoincItem.where("loinc_class like ?", "%PANEL%")
    # for each panel, find all included loinc item from loinc.form_data
    panels.each do |panel|
      paneldefs = LoincLoincFormData.where(LOINC_NUM: panel.loinc_num)
      # 11 panels have no tests defined in loinc.form_data
      if (paneldefs.length > 0)
        paneldefs.each do |paneldef|
          # ignore sub panels included in other panels
          # only start processing from top level panel
          if (paneldef.PARENT_ID == paneldef.ID)
            # top panel item
            required_in_panel = nil
            if !paneldef.OBSERVATION_REQUIRED_IN_PANEL.nil? 
              required_in_panel = paneldef.OBSERVATION_REQUIRED_IN_PANEL
            end
            answer_required = false
            if !paneldef.ANSWER_REQUIRED_YN.nil? && paneldef.ANSWER_REQUIRED_YN == 'Y'
              answer_required = true
            end
            
            toppanel = LoincPanel.create!(
              :loinc_item_id => panel.id,
              :loinc_num => paneldef.LOINC_NUM,
              :sequence_num => paneldef.SEQUENCE.to_i,
              :observation_required_in_panel => required_in_panel,
              :answer_required => answer_required,
              :type_of_entry => paneldef.TYPE_OF_ENTRY,
              :default_value => paneldef.DEFAULT_VALUE,
              :observation_required_in_phr => required_in_panel

            )
            toppanel.p_id = toppanel.id
            toppanel.save!
            
            #sub items,
            panelitems = LoincLoincFormData.where("PARENT_ID != ID and PARENT_ID =?", paneldef.ID)
            
            if !panelitems.nil? && panelitems.length>0
              panelitems.each do |panelitem|
                self.copy_a_test(panelitem, toppanel)
              end
            end
          end
        end
      else
        puts "no items in this panel: " + panel.loinc_num.to_s
      end
    end
    return true
    # loinc ver 2.26
    # total 477 panels
    # 464 panels that have tests
    # 13 panels that have no tests included
    # 101 panels that have multiple definitions (multiple test sets)
    #    no items in this panel: 24345-1
    #    no items in this panel: 35576-8
    #    no items in this panel: 49037-5
    #    no items in this panel: 50624-6
    #    no items in this panel: 50673-3
    #    no items in this panel: 52491-8
    #    no items in this panel: 52492-6
    #    no items in this panel: 52493-4
    #    no items in this panel: 52495-9
    #    no items in this panel: 53756-3
    #    no items in this panel: 53940-3
    #    no items in this panel: 54095-5
   
    # loinc ver 2.32
    #        no items in this panel: 24345-1
    #        no items in this panel: 35576-8
    #        no items in this panel: 49037-5
    #        no items in this panel: 50673-3
    #        no items in this panel: 51896-9
    #        no items in this panel: 52451-2
    #        no items in this panel: 52469-4
    #        no items in this panel: 52501-4
    #        no items in this panel: 53940-3
    #        no items in this panel: 54095-5
    #        no items in this panel: 59257-6

  end


  # item, a object of loinc.form_data
  # parent, a object of loinc_panels
  def self.copy_a_test(item, parent)
    
    required_in_panel = nil
    if !item.OBSERVATION_REQUIRED_IN_PANEL.nil? 
      required_in_panel = item.OBSERVATION_REQUIRED_IN_PANEL
    end
    answer_required = false
    if !item.ANSWER_REQUIRED_YN.nil? && item.ANSWER_REQUIRED_YN == 'Y'
      answer_required = true
    end
    loinc_item = LoincItem.find_by_loinc_num(item.LOINC_NUM)
    test = LoincPanel.create!(
      :loinc_item_id => loinc_item.id,
      :loinc_num => item.LOINC_NUM,
      :sequence_num => item.SEQUENCE.to_i,
      :observation_required_in_panel => required_in_panel,
      :answer_required => answer_required,
      :type_of_entry => item.TYPE_OF_ENTRY,
      :default_value => item.DEFAULT_VALUE,
      :p_id => parent.id,
      :observation_required_in_phr => required_in_panel

    )    
    # process sub items of the item
    panelitems = LoincLoincFormData.where(PARENT_ID: item.ID)
    
    if !panelitems.nil? && panelitems.length>0
      panelitems.each do |panelitem|
        self.copy_a_test(panelitem, test)
      end
    end
  end

  
#
# Customization starting from here
#


  def self.loinc_items_special
    # make cuff size measure included in phr
    bp = LoincItem.find_by_loinc_num('8358-4')
    bp.excluded_from_phr = false
    bp.save!

  end

  def self.loinc_panels_special
    # add phr_display_name and replace the orders of the tests for
    # 24331-1 and 53764-7
    # Lipid
    panel = LoincPanel.find_by_loinc_num('24331-1',:conditions=>"p_id=id")
    sub_fields = panel.subFields_old
    sub_fields.each do |sub_field|
      item = sub_field.loinc_item
      case sub_field.loinc_num
      when '2093-3'
        sub_field.sequence_num = 1
        item.phr_display_name = 'Cholesterol Total'
      when '2085-9'
        sub_field.sequence_num = 2
        item.phr_display_name = 'HDLc (Good Cholesterol)'
      when '9830-1'
        sub_field.sequence_num = 4
        item.phr_display_name = 'Triglyceride'
      when '13457-7'
        sub_field.sequence_num = 5
        item.phr_display_name = 'Cholesterol/HDLc Ratio'
      when '2571-8'
        sub_field.sequence_num = 3
        item.phr_display_name = 'LDLc (Bad Cholesterol)'
      end
      sub_field.save!
      item.save!
    end

    # PSA
    panel = LoincPanel.find_by_loinc_num('53764-7',:conditions=>"p_id=id")
    sub_fields = panel.subFields_old
    sub_fields.each do |sub_field|
      item = sub_field.loinc_item
      case sub_field.loinc_num
      when '12841-3'
        sub_field.sequence_num = 3
        item.phr_display_name = 'Free Prostate Specific Antigen (PSA) fraction of total'
      when '2857-1'
        sub_field.sequence_num = 1
        item.phr_display_name = 'Prostate Specific Antigen (PSA)'
      when '10886-0'
        sub_field.sequence_num = 2
        item.phr_display_name = 'Free Prostate Specific Antigen (PSA)'
      end
      sub_field.save!
      item.save!
    end

  end

  # additional answer list from RI, to be called after all loinc data,
  #   especially the answer list are migrated into phr system.
  # make up the answer_list id to start with 10000 to avoid possible conficts of
  #   new answer list released in future version of Loinc database
  def self.additional_answer_list
    answer_list_id = 10000
    loinc_num_list = TestAllAnswer.find_by_sql("select distinct loinc_num from test.ri_all_answers where loinc_num is not null and loinc_num <> ''")
    loinc_num_list.each do |record|
      loinc_num = record.loinc_num
      item = LoincItem.find_by_loinc_num(loinc_num)
      if item.nil?
        puts loinc_num + " has no corresponding records in loinc_items"
      else
        if item.answerlist_id.nil?
          # find out the new answer list and migrate them into phr database
          answer_records = TestAllAnswer.where(loinc_num: loinc_num)
          list_name = answer_records[0].TERM_TEXT
          list_desc = "for loinc item: "  + loinc_num
          if !answer_records[0].LOINC_SHORT_NAME.nil?
            list_desc += " (" + answer_records[0].LOINC_SHORT_NAME + ")"
          end
          # create answer_lists record, id should start with 625
          list_rec = AnswerList.new
          list_rec.id = answer_list_id
          list_rec.list_name = list_name
          list_rec.list_desc = list_desc
          list_rec.save!

          answer_list_id += 1
          # create answers records, id should start with 10429
          # create list_answers records，id should start with 4528
          seq_num = 1
          answer_records.each do |answer|
            answer_rec = Answer.create!(
              :answer_text => answer.ANSWER_TEXT
            )
            ListAnswer.create!(
              :answer_list_id => list_rec.id,
              :answer_id => answer_rec.id,
              :code => answer.ANSWER_CODE,
              :sequence_num => seq_num
            )
            seq_num += 1
          end
          # update loinc_items.answerlist_id
          item.answerlist_id = list_rec.id
          item.save!
        else
          puts "Loinc: " + loinc_num + " has answerlist_id: " + item.answerlist_id.to_s
        end
      end
    end
#   has existing answer list:
#    Loinc: 21440-3 has answerlist_id: 360
#    Loinc: 21441-1 has answerlist_id: 360
#    Loinc: 28008-1 has answerlist_id: 360
#    Loinc: 32854-2 has answerlist_id: 360
#    Loinc: 5802-4 has answerlist_id: 360


  end

  # not part of the preparation
  module ProcessLoinc


  # list all tests that are included in more than one panel are used by PHR
  def self.find_overlapped_tests
    @output_file = File.new('overlapped_tests_in_phr','w+')
    @output_file.sync = true

    tests_in_panels = {}
    @output_file.puts("Test Loinc#|Panel Loinc#|Test Name|Panel Name")
    # panels used in PHR and their tests
    panel_items = LoincItem.where("is_panel =? and has_top_level_panel= ? and included_in_phr =? and is_searchable=?", true, true, true, true)

    panel_items.each do |item|
      panel = LoincPanel.find_by_loinc_num(item.loinc_num, :conditions=>"p_id=id")
      tests = self.process_a_panel(panel)
      tests_in_panels[item.loinc_num] = tests
    end
    test_items = LoincItem.where("is_panel =? and has_top_level_panel= ? and included_in_phr =? and is_searchable=?", false, false, true, true)
    individual_tests = []
    test_items.each do |item|
      individual_tests << item.loinc_num
    end
    
    all_tests = []
    tests_in_panels.each do |p_loinc_num, t_loinc_nums|
      all_tests += t_loinc_nums
    end
    all_tests += individual_tests

    all_tests.uniq!

    all_tests.each do |test|
      count = 0
      first = ''
      tests_in_panels.each do |p_loinc_num, t_loinc_nums|        
        if t_loinc_nums.include?(test)
          count += 1
          # cache the first match
          if count == 1
            first = p_loinc_num
          end
          if count > 1
            # also print the first match when printing the 2nd match
            if count == 2              
              loinc_item = LoincItem.find_by_loinc_num(test)
              display_name = loinc_item.display_name
              p_loinc_item = LoincItem.find_by_loinc_num(first)
              p_display_name = p_loinc_item.display_name
              @output_file.puts("#{test}|#{first}|#{display_name}|#{p_display_name}")
            end
            loinc_item = LoincItem.find_by_loinc_num(test)
            display_name = loinc_item.display_name
            p_loinc_item = LoincItem.find_by_loinc_num(p_loinc_num)
            p_display_name = p_loinc_item.display_name
            @output_file.puts("#{test}|#{p_loinc_num}|#{display_name}|#{p_display_name}")
          end
        end
      end
    end

    @output_file.close

  end

  def self.process_a_panel(panel)
    tests = []
    sub_fields = panel.subFields
    sub_fields.each do | sub_field|
      if sub_field.has_sub_fields?
        # top level, avoid a infinite loop
        if !sub_field.is_top_level?
          sub_tests = self.process_a_panel(sub_field)
          tests = tests + sub_tests
        end
      else
        tests << sub_field.loinc_num
      end
    end
    return tests
  end

  #
  # end of finding overlapped tests in phr
  #
  end

  # not part of the preparation
  module PanelPrintOut

    
  # get the list of panels (no tests) that are used in phr system
  def self.get_phr_panels(included_in_phr = false)
    panel_items = LoincItem.where('is_panel=? and has_top_level_panel=? and included_in_phr=?',
        true, true, included_in_phr)
    panel_names = []
    panel_items.each do |panel_item|
      panel_names << [panel_item.display_name, panel_item.loinc_num]
    end
    panel_names.sort! {|s,t| s[0]<=>t[0] }

    i=1
    panel_names.each do |panel_name|
      print i.to_s + ','
      print panel_name[0] + ','
      puts panel_name[1]
      i += 1
    end

    return ''
  end


  # all of multiple loinc panels with same loinc_num has ONE top level panel
  # but some loinc panels are sub panels only, no top level panels exist for
  # its loinc_num
  def self.check_panel_def
    #get all panels form loinc.loinc
    #panels = LoincItem.where("component like ?", "%panel")
    panels = LoincItem.where("loinc_class like ?", "%PANEL%")
    # for each panel, find all included loinc item from loinc.form_data
    panels.each do |panel|
      paneldefs = LoincLoincFormData.where(LOINC_NUM: panel.loinc_num)
      # 11 panels have no tests defined in loinc.form_data
      if (paneldefs.length > 0)
        paneldefs.each do |paneldef|
          if paneldef.PARENT_ID == paneldef.ID
            puts 'top level panel:' + panel.loinc_num + '***'
          else
            puts 'sub level panel:' + panel.loinc_num
          end
        end
      end
    end
  end

  #
  # start of print panel and test names
  #
  # list all loinc_items included in panel definitions
  def self.list_all_panel_and_test_names

    @output_file = File.new('all_panels','w+')
    @output_file.sync = true
    @output_file.puts("Type|Level|Loinc #|shortame|long_common_name|component|consumer_name|datatype|hl7_v3_type")
    panels = LoincPanel.find_by_sql("select distinct id, loinc_num from loinc_panels where id = p_id")
    panels.each do |panel|
      process_a_panel(panel, 0)
      @output_file.puts "================Panel Seperator================"
    end

    @output_file.close
  end
  #
  # end of print all panel and test names
  #


  # list all loinc panels use in PHR, who have no required tests defined in loinc_panels.
  def self.list_all_panel_used_wo_required_tests
    @output_file = File.new('all_panels_in_phr_wo_required_tests','w+')
    @output_file.sync = true

    @tests_in_panels = []
    @output_file.puts("Type|Level|Loinc #|shortame|long_common_name|component|consumer_name|phr_display_name|datatype|hl7_v3_type")
    # panels used in pHR and their tests
    panel_items = LoincItem.where("is_panel =? and has_top_level_panel= ? and included_in_phr =?", true, true, true)

    panel_items.each do |item|
      panel = LoincPanel.find_by_loinc_num(item.loinc_num, :conditions=>"p_id=id")
      if !panel_has_required_fields?(panel)
        process_a_panel(panel, 0)
        @output_file.puts "================Panel Seperator================"
      end
    end
    @output_file.close

  end

  def self.panel_has_required_fields?(loinc_panel)
    rtn = false
    sub_fields = loinc_panel.subFields
    sub_fields.each do |sub_field|
      if sub_field.id != sub_field.p_id
        if sub_field.loinc_item.is_test?
          has_required = sub_field.required_in_panel?
        else
          has_required = panel_has_required_fields?(sub_field)
        end
        if has_required
          rtn = true
          break
        end
      end
    end
    return rtn
  end

  #
  # start of print panel and test names in phr
  #
  # list all loinc_items included in panel definitions that are used by PHR
  def self.list_all_panel_and_test_names_used
    @output_file = File.new('all_panels_in_phr','w+')
    @output_file.sync = true

    @tests_in_panels = []
    @output_file.puts("Type|Level|Required_in_phr|Orig_required_flag|Loinc #|shortame|long_common_name|component|consumer_name|phr_display_name|name displayed on web app|datatype|hl7_v3_type")
    # panels used in pHR and their tests
    panel_items = LoincItem.where("is_panel =? and has_top_level_panel= ? and included_in_phr =? and is_searchable=?", true, true, true, true)

    panel_items.each do |item|
      panel = LoincPanel.find_by_loinc_num(item.loinc_num, :conditions=>"p_id=id")
      process_a_panel(panel, 0)
      @output_file.puts "================Panel Seperator================"
    end
    @output_file.close

    # tests used in PHR but their top level panels are not
    @output_file = File.new('all_separate_tests_in_phr','w+')
    @output_file.sync = true

    @output_file.puts("Type|Level|Required_in_phr|Orig_required_flag|Loinc #|shortame|long_common_name|component|consumer_name|phr_display_name|name displayed on web app|datatype|hl7_v3_type")
    
    test_items = LoincItem.where("is_panel =? and has_top_level_panel= ? and included_in_phr =? and is_searchable=?", false, false, true, true)

    test_items.each do |item|
      if !@tests_in_panels.include?(item.loinc_num)
        print_a_test(item.loinc_num, 0)
      end
    end
    @output_file.close

  end
  
  def self.process_a_panel(panel, level)
    level += 1
    @tests_in_panels << panel.loinc_num
    self.print_a_panel(panel.loinc_num, level)
    sub_fields = panel.subFields
    sub_fields.each do | sub_field|
      if sub_field.has_sub_fields?
        # top level, avoid a infinite loop
        if !sub_field.is_top_level?
          self.process_a_panel(sub_field, level)
        end
      else
        @tests_in_panels << sub_field.loinc_num
        required_in_phr = sub_field.required_in_panel?
        orig_required_flag = sub_field.observation_required_in_phr
        self.print_a_test(sub_field.loinc_num, level, required_in_phr, orig_required_flag)
      end
    end
  end

  def self.print_a_panel(loinc_num, level)
    loinc_item = LoincItem.find_by_loinc_num(loinc_num)
    #puts "Panel " + level.to_s + " : " + loinc_item.loinc_num + " : " + loinc_item.display_name
    shortname = loinc_item.shortname.nil? ? "" : loinc_item.shortname
    long_common_name = loinc_item.long_common_name.nil? ? "" : loinc_item.long_common_name
    consumer_name = loinc_item.consumer_name.nil? ? "" : loinc_item.consumer_name
    phr_name = loinc_item.phr_display_name.nil? ? "" : loinc_item.phr_display_name
    component = loinc_item.component.nil? ? "" : loinc_item.component
    datatype = loinc_item.datatype.nil? ? "" : loinc_item.datatype
    hl7_v3_type = loinc_item.hl7_v3_type.nil? ? "" : loinc_item.hl7_v3_type
    display_name = loinc_item.display_name
    @output_file.puts( "Panel|" + level.to_s + "| | |" + loinc_item.loinc_num + "|" + shortname + "|"+ long_common_name + "|" + component + "|" +consumer_name + "|"+ phr_name + "|" +display_name + "|" + datatype + "|" + hl7_v3_type)

  end
  
  def self.print_a_test(loinc_num, level, required='', required_flag='')
    loinc_item = LoincItem.find_by_loinc_num(loinc_num)
    #puts " Test " + level.to_s + " : " + loinc_item.loinc_num + " : " + loinc_item.display_name
    shortname = loinc_item.shortname.nil? ? "" : loinc_item.shortname
    long_common_name = loinc_item.long_common_name.nil? ? "" : loinc_item.long_common_name
    consumer_name = loinc_item.consumer_name.nil? ? "" : loinc_item.consumer_name
    phr_name = loinc_item.phr_display_name.nil? ? "" : loinc_item.phr_display_name
    component = loinc_item.component.nil? ? "" : loinc_item.component
    datatype = loinc_item.datatype.nil? ? "" : loinc_item.datatype
    hl7_v3_type = loinc_item.hl7_v3_type.nil? ? "" : loinc_item.hl7_v3_type
    required_flag = required_flag.blank? ? "" : required_flag
    display_name = loinc_item.display_name
    @output_file.puts( " Test|" + level.to_s + "|" + required.to_s + "|" + required_flag + "|" + loinc_item.loinc_num + "|" + shortname + "|"+ long_common_name + "|" + component + "|" +consumer_name + "|" + phr_name + "|" +display_name + "|"+ datatype + "|" + hl7_v3_type)
  end
  #
  # end of print panel and test names in phr
  #


  #
  # start of print all panel names only
  #
  # list panel names only
  def self.list_all_panel_names
    @output_file = File.new('all_panel_names','w+')
    @output_file.sync = true
    @output_file.puts("loinc_num|shortame|long_common_name|component|phr_display_name|keep")
    panels = LoincItem.where(is_panel: true).order(:loinc_num)
    panels.each do |loinc_item|
      shortname = loinc_item.shortname.nil? ? "" : loinc_item.shortname
      long_common_name = loinc_item.long_common_name.nil? ? "" : loinc_item.long_common_name
      phr_name = loinc_item.phr_display_name.nil? ? "" : loinc_item.phr_display_name
      component = loinc_item.component.nil? ? "" : loinc_item.component
      datatype = loinc_item.datatype.nil? ? "" : loinc_item.datatype
      @output_file.puts( loinc_item.loinc_num + "|" + shortname + "|"+ long_common_name + "|" + component + "|" + phr_name +"|" + datatype + "|")
    end

    @output_file.close
  end
  #
  # end of print all panel names only
  #

  
  # start of print units in phr
  # 
  # list all units for panel tests included in panel definitions that are used by PHR
  def self.list_all_panel_units_used
    @output_file = File.new('all_panel_units_in_phr','w+')
    @output_file.sync = true
    @output_file.puts("Type|Level|Loinc #|name|units")
    panel_items = LoincItem.where("is_panel =? and has_top_level_panel= ? and excluded_from_phr =?", true, true, false)

    panel_items.each do |item|
      panel = LoincPanel.find_by_loinc_num(item.loinc_num, :conditions=>"p_id=id")
      process_a_panel_unit(panel, 0)
      @output_file.puts "================Panel Seperator================"
    end
    @output_file.close
  end


  def self.process_a_panel_unit(panel, level)
    level += 1
    self.print_a_panel_unit(panel.loinc_num, level)
    sub_fields = panel.subFields_old
    sub_fields.each do | sub_field|
      if sub_field.has_sub_fields?
        # top level, avoid a infinite loop
        if !sub_field.is_top_level?
          self.process_a_panel_unit(sub_field, level)
        end
      else
        self.print_a_test_unit(sub_field.loinc_num, level)
      end
    end
  end


  def self.print_a_panel_unit(loinc_num, level)
    loinc_item = LoincItem.find_by_loinc_num(loinc_num)
    name = loinc_item.display_name.nil? ? "" : loinc_item.display_name
    @output_file.puts( "Panel|" + level.to_s + "|" + loinc_item.loinc_num + "|" + name + "|")
  end


  def self.print_a_test_unit(loinc_num, level)
    loinc_item = LoincItem.find_by_loinc_num(loinc_num)
    name = loinc_item.display_name.nil? ? "" : loinc_item.display_name
    units = loinc_item.loinc_units
    @output_file.puts( " Test|" + level.to_s + "|" + loinc_item.loinc_num + "|" + name + "|" )
    units.each do |unit|
      unit_text = unit.unit.nil? ? "" : unit.unit
      @output_file.puts( " |" + "|" + loinc_item.loinc_num + "|"  + "|" + unit_text )
    end
  end
  #
  # end of print units in phr
  #


  # start of print answers in phr
  #
  # list all answers for panel tests included in panel definitions that are used by PHR
  def self.list_all_panel_answers_used
    @output_file = File.new('all_panel_answers_in_phr','w+')
    @output_file.sync = true
    @output_file.puts("Type|Level|Loinc #|name|answerlist_id|answer_code|answers")
    panel_items = LoincItem.where("is_panel =? and has_top_level_panel= ? and excluded_from_phr =?", true, true, false)

    panel_items.each do |item|
      panel = LoincPanel.find_by_loinc_num(item.loinc_num, :conditions=>"p_id=id")
      process_a_panel_answer(panel, 0)
      @output_file.puts "================Panel Separator================"
    end
    @output_file.close
  end


  def self.process_a_panel_answer(panel, level)
    level += 1
    self.print_a_panel_answer(panel.loinc_num, level)
    sub_fields = panel.subFields_old
    sub_fields.each do | sub_field|
      if sub_field.has_sub_fields?
        # top level, avoid a infinite loop
        if !sub_field.is_top_level?
          self.process_a_panel_answer(sub_field, level)
        end
      else
        self.print_a_test_answer(sub_field.loinc_num, level)
      end
    end
  end


  def self.print_a_panel_answer(loinc_num, level)
    loinc_item = LoincItem.find_by_loinc_num(loinc_num)
    name = loinc_item.display_name.nil? ? "" : loinc_item.display_name
    @output_file.puts( "Panel|" + level.to_s + "|" + loinc_item.loinc_num + "|" + name + "|"+"|"+ "|")
  end

  def self.print_a_test_answer(loinc_num, level)
    loinc_item = LoincItem.find_by_loinc_num(loinc_num)
    name = loinc_item.display_name.nil? ? "" : loinc_item.display_name
    @output_file.puts( " Test|" + level.to_s + "|" + loinc_item.loinc_num + "|" + name +"|" + "|"+ "|" )
    if !loinc_item.answerlist_id.nil?
      answers = ListAnswer.where(answer_list_id: loinc_item.answerlist_id)
      answers.each do |answer|
        answer_text = answer.answer.answer_text
        answer_code = answer.code
        @output_file.puts( " |" +  "|" + loinc_item.loinc_num + "|"  + "|" + answer.answer_list_id.to_s + "|" + answer_code + "|" + answer_text )
      end
    end
  end
  #
  # end of print answers in phr
  #


  # 10/05/2012
  # print out the existing panel classes 
  #
  def self.print_test_panel_classes
    # class
    @output_file = File.new('panel_classes','w+')
    @output_file.sync = true
    @output_file.puts("Panel Class|Code|Sequence")
    panel_class_type = Classification.find_by_class_code('panel_class')
    panel_classes = Classification.where(p_id: panel_class_type.id).order(:sequence)
    panel_classes.each do |panel_class|
      @output_file.puts "#{panel_class.class_name}|#{panel_class.class_code}|#{panel_class.sequence}"
    end
    @output_file.close

    # class and subclass
    @output_file = File.new('panel_classes_and_subclasses','w+')
    @output_file.sync = true
    @output_file.puts("Panel Class|Sub Class|Code|Sequence")
    panel_classes.each do |panel_class|
      @output_file.puts "#{panel_class.class_name}||#{panel_class.class_code}|#{panel_class.sequence}"
      sub_panel_classes = Classification.where(p_id: panel_class.id).order(:sequence)
      sub_panel_classes.each do |sub_panel_class|
        @output_file.puts "|#{sub_panel_class.class_name}|#{sub_panel_class.class_code}|#{sub_panel_class.sequence}"
      end
    end
    @output_file.close

    # classes, sub_classes and loinc items
    @output_file = File.new('panel_classes_and_loinc_items','w+')
    @output_file.sync = true
    @output_file.puts("Panel Class|Sub Class|Code|Sequence|display_name|loinc_num|loinc sequence")
    panel_classes.each do |panel_class|
      @output_file.puts "#{panel_class.class_name}||#{panel_class.class_code}|#{panel_class.sequence}"
      sub_panel_classes = Classification.where(p_id: panel_class.id).order(:sequence)
      # loinc items
      loincs = DataClass.where(classification_id: panel_class.id).order(:sequence)
      loincs.each do |loinc|
        loinc_name=LoincItem.find_by_loinc_num(loinc.item_code)
        @output_file.puts "||||#{loinc_name.display_name}|#{loinc_name.loinc_num}|#{loinc.sequence}"
      end
      sub_panel_classes.each do |sub_panel_class|
        @output_file.puts "|#{sub_panel_class.class_name}|#{sub_panel_class.class_code}|#{sub_panel_class.sequence}"
        # loinc items
        loincs = DataClass.where(classification_id: sub_panel_class.id).order(:sequence)
        loincs.each do |loinc|
          loinc_name=LoincItem.find_by_loinc_num(loinc.item_code)
          @output_file.puts "||||#{loinc_name.display_name}|#{loinc_name.loinc_num}|#{loinc.sequence}"
        end
      end
    end
    @output_file.close

  end

  # 1/18/2013
  # get a list of tests that are contained in more than one panels
  #
  # Note: For now there are 152 panels used in the PHR system
  #
  def self.print_shared_tests
    test_to_panel = {}

    # panels used in PHR
    p_items = LoincItem.where('is_panel=? and has_top_level_panel=? and included_in_phr=?', true, true, true)
    # check each panel
    p_items.each do |p_item|
      p_panel_item = LoincPanel.where('id=p_id and loinc_num=?', p_item.loinc_num).first
      sub_fields = p_panel_item.sub_fields
      # check each test within the panel
      sub_fields.each do |sub_field|
        if sub_field.id != p_panel_item.id
          if test_to_panel[sub_field.loinc_num]
            test_to_panel[sub_field.loinc_num] << p_panel_item.loinc_num
          else
            test_to_panel[sub_field.loinc_num] = [p_panel_item.loinc_num]
          end
        end
      end
    end

    # check mapping for the tests that are in more than 1 panels
    shared_tests = {}
    test_to_panel.each do |test_loinc_num, panels|
      if panels.length > 1
        shared_tests[test_loinc_num] = panels.sort
      end
    end

    @output_file = File.new('shared_tests','w+')
    @output_file.sync = true
    @output_file.puts "Test LOINC #| Panels LOINC # ..."
    shared_tests.each do |test_loinc_num, panels|

      @output_file.puts "#{test_loinc_num}|#{panels.join('|')}"
    end
    @output_file.close

    #puts shared_tests.to_yaml

  end
end
  #
  # end of print panel methods
  #


  module TestAccountData
  # 2/26/2010
  # import test panel records from an XML file.
  # not part of the loinc data preparation tool.
  def self.import_9_xml
    require 'xmlsimple'
    # TBD - specify for your system
    doc = XmlSimple.xml_in('TBD-PATHTO/9.xml', {'ForceArray'=>false})
    records = doc['Body']['NHINResponse']['Response']['RSP_Z01']['RSP_Z01.PATIENT_RESULT']['RSP_Z01.ORDER_OBSERVATION']
    puts "total number of test panel records to be imported: " + records.length.to_s

    panel_cnt =0

    obr_hash = Hash.new

    records.each do |record|
      obr_record = record['OBR']
      # key: OBR.3, OBR.4, OBR.7
      # value is a hash
      # examle:
      # {"OBR.3"=>{"EI.3"=>"FILLER ORDER NUMBER", "EI.4"=>"St Elsewhere", "EI.1"=>"FAKE-21271039", "EI.2"=>"temporary code system for order num"},
      #  "OBR.4"=>{"CE.5"=>"AUTOMATED DIFFERENTIAL", "CE.6"=>"Local Concept", "CE.1"=>"24318-8", "CE.2"=>"Diff Pan Bld", "CE.3"=>"LN", "CE.4"=>"25239"},
      #  "OBR.7"=>{"TS.1"=>"20051129"}
      # }
#      obr_record.each do |key, value|
#
#
#      end
      # get panel loinc number
      obr4 = obr_record['OBR.4']
      if !obr4.nil?
        ce1 = obr4['CE.1']
        if !ce1.nil?
#          puts 'Panel Loinc Num: ' + ce1
          panel_cnt +=1

          r = obr_hash[ce1]
          if r.nil?
            obr_hash[ce1]=1
          else
            obr_hash[ce1]=r+1
          end
        end
      end

      obx_records = record['RSP_Z01.OBSERVATION']
      if obx_records.class == Array
        obx_records.each do |obx_record|
#          obx = obx_record['OBX']
          # key: OBX.11, OBX.3, ...
          # value could be a string or a hash
          # example:
          # {"OBX.11"=>"F",
          #  "OBX.5"=>"1.3",
          #  "OBX.6"=>{"CE.2"=>"k/cumm"},
          #  "OBX.14"=>{"TS.1"=>"20051129"},
          #  "OBX.7"=>"0.8-4.8",
          #  "OBX.15"=>{"CE.1"=>"CNRLAB"},
          #  "OBX.2"=>"NM",
          #  "OBX.3"=>{"CE.5"=>"Lymphocytes #", "CE.6"=>"Local Concept", "CE.1"=>"26474-7", "CE.2"=>"Lymphocytes # Bld", "CE.3"=>"LN", "CE.4"=>"21012"}
          # }
#          obx.each do |key, value|
#
#          end
        end
      # it might not be an array ( because of the parameter of {'ForceArray'=>false})
      else
        obx_record = obx_records
#        obx = obx_record['OBX']
#        obx.each do |key, value|
#
#        end
      end
    end

    puts "total number of panels with valid loinc num: " + panel_cnt.to_s
    puts "total number of uniqure panels: " + obr_hash.keys.length.to_s
    obr_hash.each do |key,value|
      puts "Panel: " + key + "  ;record number: " + value.to_s
    end

    valid_panels = Hash.new
    # check if the panel is in phr system
    puts "\nPanels defined in PHR"
    obr_hash.each do |key, value|
      loinc_item = LoincItem.find_by_loinc_num(key)
      if loinc_item.is_panel? && loinc_item.has_top_level_panel && !loinc_item.excluded_from_phr
        puts "Panel: " + key + "  ;record number: " + value.to_s
        valid_panels[key] = value
      end
    end

    # insert the records for "Donald Duck"
    profile_id = 3361
    user_id = 3
    record_id = 0

    records.each do |record|
      obr_record = record['OBR']
      # key: OBR.3, OBR.4, OBR.7
      # value is a hash
      # examle:
      # {"OBR.3"=>{"EI.3"=>"FILLER ORDER NUMBER", "EI.4"=>"St Elsewhere", "EI.1"=>"FAKE-21271039", "EI.2"=>"temporary code system for order num"},
      #  "OBR.4"=>{"CE.5"=>"AUTOMATED DIFFERENTIAL", "CE.6"=>"Local Concept", "CE.1"=>"24318-8", "CE.2"=>"Diff Pan Bld", "CE.3"=>"LN", "CE.4"=>"25239"},
      #  "OBR.7"=>{"TS.1"=>"20051129"}
      # }
      # get panel loinc number
      obr4 = obr_record['OBR.4']
      if !obr4.nil?
        ce1 = obr4['CE.1']
        # it's a valid panel to process
        if !ce1.nil? && valid_panels.has_key?(ce1)
          whendone_et = nil
          whendone_date = nil
          whendone_hl7 = nil
          wheredone = nil
          panelname = nil

          # create a obr_order record
          panelname = obr4['CE.2']
          obr3 = obr_record['OBR.3']
          wheredone = obr3['EI.4'] unless obr3.nil?
          obr7 = obr_record['OBR.7']
          whendone = obr7['TS.1'] unless obr7.nil?
          if !whendone.nil?
            date = Time.local(whendone[0,4].to_i, whendone[4,2].to_i, whendone[6,2].to_i)
            whendone_et =date.to_i
            whendone_date = date.strftime("%Y %b %d")
            whendone_hl7 = whendone[0,4] + "/" + whendone[4,2] + "/" + whendone[6,2]
          end
          record_id += 1
          obr_rec = ObrOrder.create!(
            :latest => true,
            :loinc_num => ce1,
            :test_place => wheredone,
            :test_date => whendone_date,
            :test_date_ET => whendone_et,
            :test_date_HL7 => whendone_hl7,
            :created_by => user_id,
            :panel_name => panelname,
            :record_id => record_id,
            :profile_id => profile_id
          )

          # create obx_observation records
          obx_record_id = 0
          obx_records = record['RSP_Z01.OBSERVATION']
          if obx_records.class == Array
            obx_records.each do |obx_record|
              obx = obx_record['OBX']
              # key: OBX.11, OBX.3, ...
              # value could be a string or a hash
              # example:
              # {"OBX.11"=>"F",
              #  "OBX.5"=>"1.3",
              #  "OBX.6"=>{"CE.2"=>"k/cumm"},
              #  "OBX.14"=>{"TS.1"=>"20051129"},
              #  "OBX.7"=>"0.8-4.8",
              #  "OBX.15"=>{"CE.1"=>"CNRLAB"},
              #  "OBX.2"=>"NM",
              #  "OBX.3"=>{"CE.5"=>"Lymphocytes #", "CE.6"=>"Local Concept", "CE.1"=>"26474-7", "CE.2"=>"Lymphocytes # Bld", "CE.3"=>"LN", "CE.4"=>"21012"}
              # }
              datetype = nil
              loincnum = nil
              testname = nil
              testvalue = nil
              units = nil
              abnflag = nil
              resultstatus = nil
              refrange = nil
              whendone_et = nil
              whendone_date = nil
              whendone_hl7 = nil

              obx3 = obx['OBX.3']
              if !obx3.nil?
                loincnum = obx3['CE.1']
                testname = obx3['CE.2']
              end
              if !loincnum.nil?
                datatype = obx['OBX.2']
                testvalue = obx['OBX.5']
                if testvalue.class != String
                  testvalue = nil
                end
                obx6= obx['OBX.6']
                units = obx6['CE.2'] unless obx6.nil?
                abnflag = obx['OBX.8']
                resultstatus = obx['OBX.11']
                obx14 = obx['OBX.14']
                whendone = obx14['TS.1'] unless obx14.nil?
                if !whendone.nil?
                  date = Time.local(whendone[0,4].to_i, whendone[4,2].to_i, whendone[6,2].to_i)
                  whendone_et =date.to_i
                  whendone_date = date.strftime("%Y %b %d")
                  whendone_hl7 = whendone[0,4] + "/" + whendone[4,2] + "/" + whendone[6,2]
                end
                refrange = obx['OBX.7']
                obx_record_id += 1
                ObxObservation.create!(
                  :obr_order_id => obr_rec.id,
                  :profile_id => profile_id,
                  :latest => true,
                  :obx2_value_type => datatype,
                  :obx3_2_obs_ident => testname,
                  :obx5_value => testvalue,
                  :obx6_1_unit => units,
                  :loinc_num => loincnum,
                  :test_date => whendone_date,
                  :test_date_ET => whendone_et,
                  :test_date_HL7 => whendone_hl7,
                  :created_by => user_id,
                  :obx7_reference_ranges => refrange,
                  :record_id => obx_record_id
                )
              end
            end
          # it might not be an array ( because of the parameter of {'ForceArray'=>false})
          else
            obx_record = obx_records
            obx = obx_record['OBX']

            datetype = nil
            loincnum = nil
            testname = nil
            testvalue = nil
            units = nil
            abnflag = nil
            resultstatus = nil
            refrange = nil
            whendone_et = nil
            whendone_date = nil
            whendone_hl7 = nil

            obx3 = obx['OBX.3']
            if !obx3.nil?
              loincnum = obx3['CE.1']
              testname = obx3['CE.2']
            end
            if !loincnum.nil?
              datatype = obx['OBX.2']
              testvalue = obx['OBX.5']
              obx6= obx['OBX.6']
              units = obx6['CE.2'] unless obx6.nil?
              abnflag = obx['OBX.8']
              resultstatus = obx['OBX.11']
              obx14 = obx['OBX.14']
              whendone = obx14['TS.1'] unless obx14.nil?
              if !whendone.nil?
                date = Time.local(whendone[0,4].to_i, whendone[4,2].to_i, whendone[6,2].to_i)
                whendone_et =date.to_i
                whendone_date = date.strftime("%Y %b %d")
                whendone_hl7 = whendone[0,4] + "/" + whendone[4,2] + "/" + whendone[6,2]
              end
              refrange = obx['OBX.7']
              obx_record_id += 1
              ObxObservation.create!(
                :obr_order_id => obr_rec.id,
                :profile_id => profile_id,
                :latest => true,
                :obx2_value_type => datatype,
                :obx3_2_obs_ident => testname,
                :obx5_value => testvalue,
                :obx6_1_unit => units,
                :loinc_num => loincnum,
                :test_date => whendone_date,
                :test_date_ET => whendone_et,
                :test_date_HL7 => whendone_hl7,
                :created_by => user_id,
                :obx7_reference_ranges => refrange,
                :record_id => obx_record_id
              )
            end

          end
        end
      end
    end
  end


  def self.import_1_xml
    # import vital sign panel only
    # insert the records for "Daisy Duck"

    require 'xmlsimple'
    # TBD - specify for your system
    doc = XmlSimple.xml_in('TBD-PATHTO/1.xml', {'ForceArray'=>false})
    records = doc['Body']['NHINResponse']['Response']['RSP_Z01']['RSP_Z01.PATIENT_RESULT'][1]['RSP_Z01.ORDER_OBSERVATION']
    puts "total number of vitals test panel records to be imported: " + records.length.to_s

    profile_id = 3361
    user_id = 3
    record_id = 500
    vital_loinc_num ='34566-0'

    records.each do |record|
      obr_record = record['OBR']
      # key: OBR.3, OBR.4, OBR.7
      # value is a hash
      # examle:
      # {"OBR.3"=>{"EI.3"=>"FILLER ORDER NUMBER", "EI.4"=>"St Elsewhere", "EI.1"=>"FAKE-21271039", "EI.2"=>"temporary code system for order num"},
      #  "OBR.4"=>{"CE.5"=>"AUTOMATED DIFFERENTIAL", "CE.6"=>"Local Concept", "CE.1"=>"24318-8", "CE.2"=>"Diff Pan Bld", "CE.3"=>"LN", "CE.4"=>"25239"},
      #  "OBR.7"=>{"TS.1"=>"20051129"}
      # }
      # get panel loinc number
      obr4 = obr_record['OBR.4']
      if !obr4.nil?
        ce5 = obr4['CE.5']
        # it's a valid panel to process
        if !ce5.nil? && ce5=='VITALS'
          whendone_et = nil
          whendone_date = nil
          whendone_hl7 = nil
          wheredone = nil
          panelname = nil

          # create a obr_order record
          panelname = obr4['CE.2']
          obr3 = obr_record['OBR.3']
          wheredone = obr3['EI.4'] unless obr3.nil?
          obr7 = obr_record['OBR.7']
          whendone = obr7['TS.1'] unless obr7.nil?
          if !whendone.nil?
            date = Time.local(whendone[0,4].to_i, whendone[4,2].to_i, whendone[6,2].to_i)
            whendone_et =date.to_i
            whendone_date = date.strftime("%Y %b %d")
            whendone_hl7 = whendone[0,4] + "/" + whendone[4,2] + "/" + whendone[6,2]
          end
          record_id += 1
          obr_rec = ObrOrder.create!(
            :latest => true,
            :loinc_num => vital_loinc_num,
            :test_place => wheredone,
            :test_date => whendone_date,
            :test_date_ET => whendone_et,
            :test_date_HL7 => whendone_hl7,
            :created_by => user_id,
            :panel_name => panelname,
            :record_id => record_id,
            :profile_id => profile_id
          )

          # create obx_observation records
          obx_record_id = 0
          obx_records = record['RSP_Z01.OBSERVATION']
          if obx_records.class == Array
            obx_records.each do |obx_record|
              obx = obx_record['OBX']
              # key: OBX.11, OBX.3, ...
              # value could be a string or a hash
              # example:
              # {"OBX.11"=>"F",
              #  "OBX.5"=>"1.3",
              #  "OBX.6"=>{"CE.2"=>"k/cumm"},
              #  "OBX.14"=>{"TS.1"=>"20051129"},
              #  "OBX.7"=>"0.8-4.8",
              #  "OBX.15"=>{"CE.1"=>"CNRLAB"},
              #  "OBX.2"=>"NM",
              #  "OBX.3"=>{"CE.5"=>"Lymphocytes #", "CE.6"=>"Local Concept", "CE.1"=>"26474-7", "CE.2"=>"Lymphocytes # Bld", "CE.3"=>"LN", "CE.4"=>"21012"}
              # }
              datetype = nil
              loincnum = nil
              testname = nil
              testvalue = nil
              units = nil
              abnflag = nil
              resultstatus = nil
              refrange = nil
              whendone_et = nil
              whendone_date = nil
              whendone_hl7 = nil

              obx3 = obx['OBX.3']
              if !obx3.nil?
                loincnum = obx3['CE.1']
                testname = obx3['CE.2']
              end
              if !loincnum.nil?
                datatype = obx['OBX.2']
                testvalue = obx['OBX.5']
                if testvalue.class != String
                  testvalue = nil
                end
                obx6= obx['OBX.6']
                units = obx6['CE.2'] unless obx6.nil?
                abnflag = obx['OBX.8']
                resultstatus = obx['OBX.11']
                obx14 = obx['OBX.14']
                whendone = obx14['TS.1'] unless obx14.nil?
                if !whendone.nil?
                  date = Time.local(whendone[0,4].to_i, whendone[4,2].to_i, whendone[6,2].to_i)
                  whendone_et =date.to_i
                  whendone_date = date.strftime("%Y %b %d")
                  whendone_hl7 = whendone[0,4] + "/" + whendone[4,2] + "/" + whendone[6,2]
                end
                refrange = obx['OBX.7']
                obx_record_id += 1
                ObxObservation.create!(
                  :obr_order_id => obr_rec.id,
                  :profile_id => profile_id,
                  :latest => true,
                  :obx2_value_type => datatype,
                  :obx3_2_obs_ident => testname,
                  :obx5_value => testvalue,
                  :obx6_1_unit => units,
                  :loinc_num => loincnum,
                  :test_date => whendone_date,
                  :test_date_ET => whendone_et,
                  :test_date_HL7 => whendone_hl7,
                  :created_by => user_id,
                  :obx7_reference_ranges => refrange,
                  :record_id => obx_record_id
                )
              end
            end
          # it might not be an array ( because of the parameter of {'ForceArray'=>false})
          else
            obx_record = obx_records
            obx = obx_record['OBX']

            datetype = nil
            loincnum = nil
            testname = nil
            testvalue = nil
            units = nil
            abnflag = nil
            resultstatus = nil
            refrange = nil
            whendone_et = nil
            whendone_date = nil
            whendone_hl7 = nil

            obx3 = obx['OBX.3']
            if !obx3.nil?
              loincnum = obx3['CE.1']
              testname = obx3['CE.2']
            end
            if !loincnum.nil?
              datatype = obx['OBX.2']
              testvalue = obx['OBX.5']
              if testvalue.class != String
                testvalue = nil
              end
              obx6= obx['OBX.6']
              units = obx6['CE.2'] unless obx6.nil?
              abnflag = obx['OBX.8']
              resultstatus = obx['OBX.11']
              obx14 = obx['OBX.14']
              whendone = obx14['TS.1'] unless obx14.nil?
              if !whendone.nil?
                date = Time.local(whendone[0,4].to_i, whendone[4,2].to_i, whendone[6,2].to_i)
                whendone_et =date.to_i
                whendone_date = date.strftime("%Y %b %d")
                whendone_hl7 = whendone[0,4] + "/" + whendone[4,2] + "/" + whendone[6,2]
              end
              refrange = obx['OBX.7']
              obx_record_id += 1
              ObxObservation.create!(
                :obr_order_id => obr_rec.id,
                :profile_id => profile_id,
                :latest => true,
                :obx2_value_type => datatype,
                :obx3_2_obs_ident => testname,
                :obx5_value => testvalue,
                :obx6_1_unit => units,
                :loinc_num => loincnum,
                :test_date => whendone_date,
                :test_date_ET => whendone_et,
                :test_date_HL7 => whendone_hl7,
                :created_by => user_id,
                :obx7_reference_ranges => refrange,
                :record_id => obx_record_id
              )
            end

          end
        end
      end
    end

  end

  # 9/1/2010
  # not part of the preparation
  # add normal_high/low, danger_high/low value in the obx_observations table
  # for user 'Daisy Duck'
  def self.update_daisy_duck()
    profile_id = Phr.find_by_pseudonym('Daisy Duck').profile_id
    obx_records = ObxObservation.where('profile_id=? and latest=?', profile_id, true)
    obx_records.each do |obx_rec|
      loinc_num = obx_rec.loinc_num
      unit = obx_rec.obx6_1_unit
      if !unit.blank?
        loinc_item = LoincItem.find_by_loinc_num(loinc_num)
        if loinc_item
          unit_records = loinc_item.loinc_units
          # find the matching unit
          unit_records.each do |unit_rec|
            if !unit_rec.unit.nil? && unit_rec.unit.downcase == unit.downcase
              obx_rec.test_normal_high = unit_rec.norm_high
              obx_rec.test_normal_low = unit_rec.norm_low
              obx_rec.test_danger_high = unit_rec.danger_high
              obx_rec.test_danger_low = unit_rec.danger_low
              obx_rec.obx6_1_unit = unit_rec.unit
              obx_rec.unit_code = unit_rec.id
              obx_rec.save!
              puts loinc_num + ' fount unit'
              break
            end
          end
        end
      end
    end

  end

  # 5/13/2010
  # for those imported test panel records from an XML file, add a random time
  # value
  # not part of the loinc data preparation tool.
  def self.add_time_value
    # daisy duck's profile id
    profile_id=3361
    obr_records = ObrOrder.where("profile_id=? and test_date_time is null", profile_id)

    obr_records.each do |obr_rec|
      test_date = obr_rec.test_date
      date_obj = Date.parse(test_date)
      year= date_obj.year
      month = date_obj.month
      day = date_obj.day
      hour_random = rand(12)
      #hour_random =12 if hour_random ==0
      minute_random = rand(60)
      if rand(2) ==1
        ampm_random = 'PM'
        hour_random_t = hour_random + 12
      else
        ampm_random = 'AM'
        hour_random_t = hour_random
      end
      time_string = hour_random.to_s + ':' + sprintf("%02d",minute_random) + ' ' + ampm_random

#puts test_date
#puts year.to_s
#puts month.to_s
#puts day.to_s
#puts hour_random_t.to_s
#puts minute_random.to_s
      time_obj = Time.utc(year,month,day,hour_random_t,minute_random)
      test_date_et = time_obj.to_i * 1000

      obr_rec.test_date_ET = test_date_et
      obr_rec.test_date_time = time_string

      puts test_date_et.to_s
      puts time_string
      obr_rec.save!
    end
  end

  end
  #
  # end of TestAccountData
  #


  #
  # 4/20/2009, Clem handpicked 114 panels to be inlcuded in PHR
  def self.select_panels_for_phr
    # make the 1 the default value of "excluded_from_phr" for panels
    LoincItem.update_all("excluded_from_phr = 1", "is_panel = 1 ")
    
    # update panel names if there's a change
    selected_panels = LoincPanelList.where(keep: 1)
    selected_panels.each do |panel_name|
      item = LoincItem.find_by_loinc_num(panel_name.loinc_num)
      if !item.nil?
        item.excluded_from_phr = false
        if !panel_name.phr_display_name.nil?
          item.phr_display_name = panel_name.phr_display_name
        end
        item.save!
      else
        puts "no loinc item found for " + panel_name.loinc_num
      end
    end
  end


  # 4/23/2009, Add a 'has_top_level_panel' column in loinc_items table
  # so that in adding new panels, it only searches names of top level panels
  def self.update_has_top_level_panel
    # make the default value of has_top_level_panel to false
    LoincItem.update_all("has_top_level_panel = 0")

    panel_items = LoincItem.where(is_panel: true)
    panel_items.each do |panel_item|
      panel = LoincPanel.find_by_loinc_num(panel_item.loinc_num,:conditions=>["p_id=id"])
      # if it is a top level panel
      if !panel.nil?
        panel_item.has_top_level_panel = true
        panel_item.save!
      end
    end

  end

  # 5/14/2009, add ranges from data in 17 new panels and other sources
  def self.update_normal_ranges
    # No. 1
    # in the 17 new panels ,there are some normal range info
    # since it is difficult to match the units with units in the ranges
    # here I just copy the data from the list and make a hash
    loinc_units_ranges_hash = {
      "10230-1"=>["%","50 to 75 %"],
      "11034-6"=>["nmol/L","<0.4 nmol/L"],
      "11561-8"=>["% inhibition","<15 % inhibition"],
      "14957-5"=>["mg/L","<20 mg/L"],
      "20570-8"=>["%","39 to 51 %"],
      "2345-7"=>["mg/dL","74 to 106 mg/dL"],
      "26450-7"=>["%","0 to 2 %"],
      "26453-1"=>["/L","4.10 to 5.90 x 10(12)/L"],
      "26464-8"=>["k/cumm","4.4 to 11.3 x10(9)/L"],
      "26478-8"=>["%","24 to 40 %"],
      "26485-3"=>["%","4 to 9 %"],
      "26511-6"=>["%","47 to 63 %"],
      "26515-7"=>["k/cumm","172 to 450 x10(9)/L"],
      "27353-2"=>["mg/dL","74 to 106 mg/dL"],
      "28539-5"=>["pg","27 to 22 pg/red cell"],
      "28540-3"=>["g/dL","33 to 35 g/dL"],
      "30180-4"=>["%","0 to 2 %"],
      "30192-9"=>["%","<20 %"],
      "30428-7"=>["fL","80 to 96 fl/red cell"],
      "33762-6"=>["pg/mL","<67 pg/mL"],
      "39156-5"=>["kg/m2","18 to 25 kg/m2"],
      "41653-7"=>["mg/dL","74 to 106 mg/dL"],
      "4548-4"=>["%","3.8 to 6.4 %"],
      "48065-7"=>["ug/L FEU","<0.5 ug/L FEU"],
      "48066-5"=>["ug/L DDU","<2 ug/L DDU"],
      "5792-7"=>["mg/dL","neg"],
      "718-7"=>["g/dL","12.0 to 16.0 g/dL"]
      }

    loinc_units_ranges_hash.each do |k,v|
      unit_records = LoincUnit.where("loinc_num =? and unit = ?", k, v[0])
      if !unit_records.nil? && !unit_records.empty?
        unit_records.each do |rec|
          rec.norm_range = v[1]
          rec.save!
        end
      else
        puts "units " + v[0] + " not found for " + k
      end

    end


    # No. 2
    # there's a seperate spread sheet that contains some ranges
    # pick those matches the units and loinc_num and put them into our db
    # if there are multiple matches, just pick the 1st one
    
  end

  # 11/1/2010
  # replacing the update_units_and_data_type
  # just remove the duplicated units
  def self.remove_duplicated_units
    # unify '/min', --eCHN, '/MIN' --RI
    LoincUnit.update_all("unit='/min'", "unit='/MIN'")
    # unify 'mosm/kg' --eCHN , 'mOsmol/kg' --RI
    LoincUnit.update_all("unit='mosm/kg'", "unit='mOsMol/kg'")
    # unify 'minutes" -- eCHN, 'min' -- RI
    LoincUnit.update_all("unit='minutes'", "unit='min'")
    # unify 'units/L' -- RI, 'U/L' --eCHN  ,
    LoincUnit.update_all("unit='units/L'", "unit='U/L'")
    # unify 'seconds' --eCHN, 'sec' --RI
    LoincUnit.update_all("unit='seconds'", "unit='sec'")
    # unify 'pounds', 'lb' --RI
    # no 'pounds' in ver 2.32
    LoincUnit.update_all("unit='pounds'", "unit='lb'")
    # unify '% INHIBITION', --RI '% inhibition
    # no '% inhibition' in ver 2.32
    LoincUnit.update_all("unit='% inhibition'", "unit='% INHIBITION'")
    # unify 'cm', 'centimeters'
    # no 'centimeters' in ver 2.32
    LoincUnit.update_all("unit='centimeters'", "unit='cm'")

    # 11/3/2010
    # unify 'INCH(S)', 'inches'
    LoincUnit.update_all("unit='inches'", "unit='INCH(S)'")
    # unify 'hr', 'hours'
    LoincUnit.update_all("unit='hours'", "unit='hr'")

    # remove duplicated units
    # keep the RI source if there are multiple sources
    unit_recs = LoincUnit.find_by_sql("select distinct loinc_num from loinc_units")
    unit_recs.each do |unit_rec|
      loinc_num = unit_rec.loinc_num
      units = LoincUnit.where(loinc_num: loinc_num).order('unit, source_id asc')

      prev_unit = nil
      units.each do |unit|
        if !prev_unit.nil? && unit.unit == prev_unit
          unit.destroy
          puts unit.unit + " is duplicated. " + unit.loinc_num + " :prev: " + prev_unit
        end
        prev_unit = unit.unit
      end
    end

  end
  # 11/1/2010
  # data types are supplied in ver 2.32.
  # not used
  #
  # 5/5/2009 remove duplicated units,
#  def self.update_units_and_data_type
#    #
#    # update hl7_v3_type based on scale_typ and datatype
#    #   scale_typ   ---->  hl7_v3_type
#    #          Qn          PQ
#    #         Ord          CWE
#    #         Nom          CWE
#    #
#    #    datatype   ---->  hl7_v3_type
#    #          CE          CWE
#    #          NM          PQ
#    #
#
#    # remove duplicated units
#    # 'mosm/kg' , 'mOsmol/kg'     --> remove 'mOsMol/kg'
#    # 'min', 'minutes"            --> remove 'minutes'
#    # 'units/L', 'U/L'            --> remove 'U/L'
#
#    sql_statement = "update loinc_items set hl7_v3_type = 'PQ' where scale_typ='Qn'"
#    ActiveRecord::Base.connection.execute(sql_statement)
#    sql_statement = "update loinc_items set hl7_v3_type = 'CWE' where scale_typ='Ord'"
#    ActiveRecord::Base.connection.execute(sql_statement)
#    sql_statement = "update loinc_items set hl7_v3_type = 'CWE' where scale_typ='Nom'"
#    ActiveRecord::Base.connection.execute(sql_statement)
#    sql_statement = "update loinc_items set hl7_v3_type = 'CWE' where datatype='CE'"
#    ActiveRecord::Base.connection.execute(sql_statement)
#    sql_statement = "update loinc_items set hl7_v3_type = 'PQ' where datatype='NM'"
#    ActiveRecord::Base.connection.execute(sql_statement)
#    # 4/20/2009, Clem wanted all loinc items that have a answer list to be of 'CWE' data type
#    # so that the unit and range will not be editable for these tests
#    LoincItem.update_all("datatype = 'CWE'", "answerlist_id is not null and datatype is null")
#
#    # pre-process
#    # unify '/min', '/MIN'
#    LoincUnit.update_all("unit='/min'", "unit='/MIN'")
#    # unify 'mosm/kg' , 'mOsmol/kg',
#    LoincUnit.update_all("unit='mosm/kg'", "unit='mOsMol/kg'")
#    # unify 'minutes" , 'min'
#    LoincUnit.update_all("unit='minutes'", "unit='min'")
#    # unify 'units/L', 'U/L'  ,
#    LoincUnit.update_all("unit='units/L'", "unit='U/L'")
#    # unify 'seconds', 'sec'
#    LoincUnit.update_all("unit='seconds'", "unit='sec'")
#    # unify 'pounds', 'lb'
#    LoincUnit.update_all("unit='pounds'", "unit='lb'")
#    # unify '% INHIBITION', '% inhibition
#    LoincUnit.update_all("unit='% inhibition'", "unit='% INHIBITION'")
#    # unify 'cm', 'centimeters'
#    LoincUnit.update_all("unit='centimeters'", "unit='cm'")
#
#    # remove duplicated units
#    unit_recs = LoincUnit.find_by_sql("select distinct loinc_num from loinc_units")
#    unit_recs.each do |unit_rec|
#      loinc_num = unit_rec.loinc_num
#      units = LoincUnit.where(loinc_num: loinc_num).order('unit, id asc')
#
#      prev_unit = nil
#      units.each do |unit|
#        if !prev_unit.nil? && unit.unit == prev_unit
#          unit.destroy
#          puts unit.unit + " is duplicated. " + unit.loinc_num + " :prev: " + prev_unit
#        end
#        prev_unit = unit.unit
#      end
#    end
#
#
#    return true
#  end

  # 11/3/2010
  # units mapping
  def self.replace_units(units)
    new_units = units
    case units
    when 'sec'
      new_units = 'seconds'
    when 'min'
      new_units = 'minutes'
    when 'hr'
      new_units = 'hours'
    when 'U/L'
      new_units = 'units/L'
    when '/MIN'
      new_units = '/min'
    when 'INCH(S)'
      new_units = 'inches'
    when 'cm'
      new_units = 'centimeters'
    when 'lb'
      new_units = 'pounds'
    when 'mOsMol/kg'
      new_units = 'mosm/kg'
    when 'INHIBITION'
      new_units = 'inhibition'
    end

    return new_units
  end
  # 5/15/2009, from Kathy, new normal_range and units (if not existing) picked up
  # from the new LOINC item of some phr panels
  # 11/1/2010
  # update units range from the column 'curated_range_and_units'
  def self.new_normal_range_and_units
    # range_recs = TestNewNormalRange.where(excluded: 0)
    range_recs = LoincItem.where('curated_range_and_units is not null')
    range_recs.each do | range_rec|
      loinc_num = range_rec.loinc_num
      range_text = range_rec.curated_range_and_units
      # find the loinc item
      loinc_item = LoincItem.find_by_loinc_num(loinc_num)
      loinc_item.norm_range =range_text
      loinc_item.save!
      # parse range text
      if range_text == 'neg'
        # find all units
        units_recs = LoincUnit.where(loinc_num: loinc_num)
        units_recs.each do |units_rec|
          if units_rec.norm_range.blank?
            units_rec.norm_range = range_text
            units_rec.save!
          end
        end
      else
        range_and_units = range_text.split('|')
        range_and_units.each do |range_units|
          temp_array = range_units.split(';')
          range = temp_array[0]
          units = temp_array[1]
          # replace some units
          units = self.replace_units(units)
          # find units records, it might have dulipcated records,
          # duplicated units records are removed in function
          # update_units_and_data_type
          units_recs = LoincUnit.where("loinc_num=? and unit=?", loinc_num, units)
          # if this units is not in db, create a new record with range
          if units_recs.empty?
            LoincUnit.create!(
                :loinc_item_id=>loinc_item.id,
                :loinc_num => loinc_num,
                :norm_range => range,
                :unit => units,
                :source_type => 'PHR',
                :source_id => 3
            )
          # if it is there, update range
          else
            units_recs.each do | units_rec|
              units_rec.norm_range = range
              units_rec.save!
            end
          end
        end
      end

    end
  end

  # 11/1/2010
  # the data processed by new_loinc_panel_and_answer_list_and_units
  # are in the ver 2.32
  # new_loinc_panel_and_answer_list_and_units is no longer needed.
  # But need to set excluded_in_phr to false 
  # use add_new_panels instead of new_loinc_panel_and_answer_list_and_units
  def self.add_new_panels
    new_panels = TestNewPanel.where(sequence: 0)
    new_panels.each do | new_panel|
      loinc_num = new_panel.LOINC_NUM
      panel_item = LoincItem.find_by_loinc_num(loinc_num)
      # if there's a new loinc item, add it to loinc_items
      if panel_item.nil?
        puts "item in test.new_panels: #{loinc_num} is not in loinc_items"
      else
        panel_item.excluded_from_phr = false
        panel_item.save!
      end
    end
  end
#  # 5/7/2009
#  # 15 new test panels and related answer lists from RI
#  # will appear in the LOINC release of June 2009
#  # add it into our database anyway.
#  #
#  # There will be more Loinc Items and answer list in the new release.
#  # These 15 panels include some new Loinc items and some new answer lists. so
#  # the IDs (loinc_num, and answer_list_id) are not continuous.
#  #
#  # In order to keep same answer list id as in the official Loinc database. Our
#  # customized answer list will start from 10000, as in above function
#  #   addition_answer_list
#  def self.new_loinc_panel_and_answer_list_and_units
#    # add new answer lists
#    answer_lists = TestNewAnswerList.where(code: '0')
#    answer_lists.each do | answer_list |
#      # create an answer_lists record
#      list_rec = AnswerList.new
#      list_rec.id = answer_list.list_id.to_i
#      list_rec.list_desc ='new list that will appear in june 2009 release of Loinc'
#      list_rec.save!
#      # create answers records
#      answers = TestNewAnswerList.where("list_id=? AND code <> '0'", answer_list.list_id).order(:sequence)
#      answers.each do | answer |
#        answer_rec = Answer.create!(
#          :answer_text => answer.answer
#        )
#        # create list_answers records
#        ListAnswer.create!(
#          :answer_list_id => list_rec.id,
#          :answer_id => answer_rec.id,
#          :code => answer.code,
#          :sequence_num => answer.sequence.to_i
#        )
#      end
#    end # end of answer_lists.each
#
#    # add new panel definitions to loinc_panels
#    new_panels = TestNewPanel.where(sequence: 0)
#    new_panels.each do | new_panel|
#      loinc_num = new_panel.LOINC_NUM
#      panel_item = LoincItem.find_by_loinc_num(loinc_num)
#      # if there's a new loinc item, add it to loinc_items
#      if panel_item.nil?
#        panel_item = LoincItem.create!(
#          :loinc_num => loinc_num,
#          :component => new_panel.COMPONENT,
#          :property  => new_panel.PROPERTY,
#          :time_aspct   => new_panel.TIME_ASPCT,
#          :loinc_system => new_panel.SYSTEM,
#          :scale_typ => new_panel.SCALE_TYP,
#          :method_typ   => new_panel.METHOD_TYP,
#          :shortname => nil,
#          :long_common_name => nil,
#          :datatype => new_panel.HL7_V3_DATATYPE,
#          :relatednames2 => nil,
#          :unitsrequired => 'N',
#          :example_units => new_panel.EXAMPLE_UNITS,
#          :norm_range => new_panel.CURATED_RANGE_AND_UNITS,
#          :loinc_class => nil,
#          :common_tests => nil,
#          :answerlist_id => new_panel.ANSWERLIST_ID,
#          :is_panel => true,
#          :loinc_version => '2.32',
#          :excluded_from_phr => false,
#          :phr_display_name =>new_panel.COMPONENT, # new_panel.CONSUMER_NAME,
#          :help_url => nil,
#          :has_top_level_panel => true,
#          :hl7_v3_type => new_panel.HL7_V3_DATATYPE,
#          :help_text => new_panel.DEFINITION_DESCRIPTION_HELP
#        )
#      # update answerlist_id if it's an exsting loinc item
#      else
#        if !new_panel.ANSWERLIST_ID.nil?
#          panel_item.answerlist_id = new_panel.ANSWERLIST_ID
#          panel_item.save!
#        end
#      end
#      # create panel records
#      toppanel = LoincPanel.create!(
#        :loinc_item_id => panel_item.id,
#        :loinc_num => loinc_num,
#        :sequence_num => 0,
#        :observation_required_in_panel => new_panel.OBSERVATION_REQUIRED_IN_PANEL,
#        :answer_required => nil,
#        :type_of_entry => 'Q',
#        :default_value => nil,
#        :observation_required_in_phr => new_panel.OBSERVATION_REQUIRED_IN_PANEL
#      )
#      toppanel.p_id = toppanel.id
#      toppanel.save!
#
#      # process tests in a panel
#      new_tests = TestNewPanel.where("PANEL =? and sequence<>0 ", new_panel.PANEL).order(:sequence)
#      new_tests.each do |new_test|
#        test_loinc_num = new_test.LOINC_NUM
#        test_item = LoincItem.find_by_loinc_num(test_loinc_num)
#        # create the loinc item if it does not exist
#        if test_item.nil?
#          test_item = LoincItem.create!(
#            :loinc_num => test_loinc_num,
#            :component => new_test.COMPONENT,
#            :property  => new_test.PROPERTY,
#            :time_aspct   => new_test.TIME_ASPCT,
#            :loinc_system => new_test.SYSTEM,
#            :scale_typ => new_test.SCALE_TYP,
#            :method_typ   => new_test.METHOD_TYP,
#            :shortname => nil,
#            :long_common_name => nil,
#            :datatype => new_test.HL7_V3_DATATYPE,
#            :relatednames2 => nil,
#            :unitsrequired => 'N',
#            :example_units => new_test.EXAMPLE_UNITS,
#            :norm_range => new_test.CURATED_RANGE_AND_UNITS,
#            :loinc_class => nil,
#            :common_tests => nil,
#            :answerlist_id => new_test.ANSWERLIST_ID,
#            :is_panel => false,
#            :loinc_version => '2.32',
#            :excluded_from_phr => false,
#            :phr_display_name => new_test.CONSUMER_NAME,
#            :help_url => nil,
#            :has_top_level_panel => false,
#            :hl7_v3_type => new_test.HL7_V3_DATATYPE,
#            :help_text => new_test.DEFINITION_DESCRIPTION_HELP
#          )
#        # update answerlist_id if it's an exsting loinc item
#        else
#          if !new_test.ANSWERLIST_ID.nil?
#            test_item.answerlist_id = new_test.ANSWERLIST_ID
#            test_item.save!
#          end
#          if !new_test.HL7_V3_DATATYPE.blank?
#            test_item.hl7_v3_type = new_test.HL7_V3_DATATYPE
#            test_item.datatype = new_test.HL7_V3_DATATYPE
#            test_item.save!
#          end
#          if !new_test.CONSUMER_NAME.blank?
#            test_item.phr_display_name = new_test.CONSUMER_NAME
#            test_item.save!
#          end
#          if !new_test.EXAMPLE_UNITS.blank?
#            test_item.example_units = new_test.EXAMPLE_UNITS
#            test_item.save!
#          end
#
#        end
#        example_units = test_item.example_units
#        # update loinc_units
#        if !example_units.nil? && !example_units.empty?
#          units_list = example_units.split(';')
#          units_list.each do | one_units|
#            one_units = one_units.strip
#            if !one_units.empty?
#              LoincUnit.create!(
#                :loinc_item_id => test_item.id,
#                :loinc_num => test_item.loinc_num,
#                :unit => one_units
#              )
#            end
#          end
#        end
#        # create a loinc panel record
#        LoincPanel.create!(
#          :p_id => toppanel.id,
#          :loinc_item_id => test_item.id,
#          :loinc_num => test_loinc_num,
#          :sequence_num => new_test.sequence,
#          :observation_required_in_panel => new_test.OBSERVATION_REQUIRED_IN_PANEL,
#          :answer_required => nil,
#          :type_of_entry => 'Q',
#          :default_value => nil,
#          :observation_required_in_phr => new_test.OBSERVATION_REQUIRED_IN_PANEL
#        )
#      end # end of new_tests.each, for each tests in a panel
#    end # end of new_panels.each, for each panel
#
#    # 5/14/2009
#    # add missing answerlist_id for 5 loinc_items, based on spread sheet
#    #  PHR_ANSWER from Kathy,
#    answer_list_ids = {'11125-2'=>715,
#                       '11156-7'=>716,
#                       '20081-6'=>739,
#                       '3150-0' =>738,
#                       '3151-8' =>737
#                      }
#    answer_list_ids.each do |k,v|
#      item = LoincItem.find_by_loinc_num(k)
#      item.answerlist_id = v
#      item.save!
#    end
#
#
#
#    # 5/18/2009
#    # update phr_display_name
#    records = TestPhrLoinc.all
#    records.each do |record|
#      loinc_num = record.LOINC_NUM
#      loinc_item = LoincItem.find_by_loinc_num(loinc_num)
#      if !loinc_item.nil?
#        if !record.LONG_COMMON_NAME.blank?
#          loinc_item.long_common_name = record.LONG_COMMON_NAME
#        end
#        if !record.HL7_V3_DATATYPE.blank?
#          loinc_item.hl7_v3_type = record.HL7_V3_DATATYPE
#        end
#        if !record.SHORTNAME.blank?
#          loinc_item.shortname = record.SHORTNAME
#        end
#        if !record.COMPONENT.blank?
#          loinc_item.component = record.COMPONENT
#        end
#        if !record.CONSUMER_NAME.blank?
#          loinc_item.phr_display_name = record.CONSUMER_NAME
#        end
#        loinc_item.save!
#      else
#        puts "not found: " + loinc_num
#      end
#    end
#
#  end # end of function

  
  # 5/12/2009
  # additional ranges from a seperated spread sheet with over 50% duplications
  # i.e. multiple range for same units
  # for now, just pick the 1st one
  def self.addtional_normal_range_and_units
    sql_statement = "SELECT distinct loinc_num, units FROM test.ri_normal_ranges r where loinc_num <> '' and units <> '' "
    range_records = TestNormalRange.find_by_sql(sql_statement)

    range_records.each do |range_rec|
      units = self.replace_units(range_rec.units)
      # pick 1st record for one loinc_num and units
      full_range_rec = TestNormalRange.where("loinc_num=? and units=?",range_rec.loinc_num, range_rec.units).first

      loinc_units_rec = LoincUnit.where("loinc_num=? and unit=?", range_rec.loinc_num, units).first
      # no such units existing, add a new one
      if loinc_units_rec.nil?
        puts "new units " + units + " for " + range_rec.loinc_num
        loinc_item_rec = LoincItem.find_by_loinc_num(range_rec.loinc_num)
        LoincUnit.create!(
          :loinc_item_id=> loinc_item_rec.id,
          :loinc_num => range_rec.loinc_num,
          :unit => units,
          :norm_range=>full_range_rec.NORMAL_RANGE_TEXT,
          :norm_high=>full_range_rec.NORMAL_HIGH,
          :norm_low=>full_range_rec.NORMAL_LOW,
          :danger_high=>full_range_rec.LIFE_ENDANGERING_HIGH,
          :danger_low=>full_range_rec.LIFE_ENDANGERING_LOW,
          :source_type=>'RI-PHR',
          :source_id => 5
        )
      # existing units, update normal range if it's not there
      else
        puts "existing units " + units + " for " + range_rec.loinc_num
        if loinc_units_rec.norm_range.nil? && !full_range_rec.NORMAL_RANGE_TEXT.blank?
          loinc_units_rec.norm_range = full_range_rec.NORMAL_RANGE_TEXT
        end
        if loinc_units_rec.norm_high.nil? && !full_range_rec.NORMAL_HIGH.blank?
          loinc_units_rec.norm_high = full_range_rec.NORMAL_HIGH
        end
        if loinc_units_rec.norm_low.nil? && !full_range_rec.NORMAL_LOW.blank?
          loinc_units_rec.norm_low = full_range_rec.NORMAL_LOW
        end
        if loinc_units_rec.danger_high.nil? && !full_range_rec.LIFE_ENDANGERING_HIGH.blank?
          loinc_units_rec.danger_high = full_range_rec.LIFE_ENDANGERING_HIGH
        end
        if loinc_units_rec.danger_low.nil? && !full_range_rec.LIFE_ENDANGERING_LOW.blank?
          loinc_units_rec.danger_low = full_range_rec.LIFE_ENDANGERING_LOW
        end
        loinc_units_rec.save!
      end

    end

    # update norm_range
    loinc_units_records = LoincUnit.all
    loinc_units_records.each do |unit_rec|
      range_text = unit_rec.norm_range
      if range_text.blank?
        high_text = unit_rec.read_attribute(:norm_high)
        low_text =  unit_rec.read_attribute(:norm_low)
        if !high_text.blank?
          if !low_text.blank?
            range_text = low_text + " - " + high_text
          else
            range_text = " < " + high_text
          end
        elsif !low_text.blank?
          range_text = " > " + low_text
        end
        # if there's a change
        if !range_text.blank?
          unit_rec.norm_range = range_text
          unit_rec.save!
        end
      end
    end # end of updating norm_range

  end

  # some special process for PHR, mostly for some demos
  def self.phr_special_modification
    # no normal range for weight 29463-7
    records = LoincUnit.where(loinc_num: '29463-7')
    records.each do |record|
      record.norm_range =nil
      record.save!
    end
    # no normal range for heart rate max 55426-1
    records = LoincUnit.where(loinc_num: '55426-1')
    records.each do |record|
      record.norm_range =nil
      record.save!
    end
    # no normal range for heart rate avg 55425-3
    records = LoincUnit.where(loinc_num: '55425-3')
    records.each do |record|
      record.norm_range =nil
      record.save!
    end

    # add range for blirubin , 14631-6
    records = LoincUnit.where(loinc_num: '14631-6')
    records.each do |record|
      record.norm_range ="0.3 - 1.0"
      record.save!
    end

    # change name of 55429-5
    loinc_item = LoincItem.find_by_loinc_num('55429-5')
    loinc_item.phr_display_name = 'Simple hemogram & differential count'
    loinc_item.save!
  end

  # 11/1/2010
  # PHENX items should have been included in ver 2.32

#
#
#  # 8/3/2009
#  # 1 new PhenX panel and related answer lists and units
#  #
#  # There will be more Loinc Items and answer list in the new release.
#  # This panel includea some new Loinc items and some new answer lists. so
#  # the IDs (loinc_num, and answer_list_id) are not continuous.
#  #
#  # In order to keep same answer list id as in the official Loinc database. Our
#  # customized answer list will start from 10000, as in above function
#  #   addition_answer_list
#  def self.add_phenx
#    self.phenx_panel
#    self.phenx_answer_list
#    self.phenx_panel_form2
#  end
#
#  def self.phenx_panel
#    # add new loinc item or update existing loinc item names
#    phenx_items = TestPhenxLoinc.all
#    phenx_items.each do |item|
#      # check if it is already in our system
#      loinc_item = LoincItem.find_by_loinc_num(item.LOINC_NUM)
#      # create a new record
#      if loinc_item.nil?
#        loinc_item = LoincItem.create!(
#          :loinc_num => item.LOINC_NUM,
#          :component => item.COMPONENT,
#          :property  => item.PROPERTY,
#          :time_aspct   => item.TIME_ASPCT,
#          :loinc_system => item.SYSTEM,
#          :scale_typ => item.SCALE_TYP,
#          :method_typ   => item.METHOD_TYP,
#          :shortname => item.SHORTNAME,
#          :long_common_name => item.LONG_COMMON_NAME,
#          :datatype => item.HL7_V3_DATATYPE,
#          :relatednames2 => item.RELATEDNAMES2,
#          :unitsrequired => 'N',
#          :example_units => item.EXAMPLE_UNITS,
#          :norm_range => item.CURATED_RANGE_AND_UNITS,
#          :loinc_class => item.CLASS,
#          :common_tests => nil,
#          :answerlist_id => nil,
#          :is_panel => false,
#          :loinc_version => '2.32',
#          :excluded_from_phr => false,
#          :phr_display_name => item.CONSUMER_NAME,
#          :help_url => nil,
#          :has_top_level_panel => false,
#          :hl7_v3_type => item.HL7_V3_DATATYPE,
#          :help_text => item.DEFINITION_DESCRIPTION_HELP
#        )
#
#        # update loinc_units
#        if !loinc_item.example_units.nil? && !loinc_item.example_units.empty?
#          units_list = loinc_item.example_units.split(';')
#          units_list.each do | one_units|
#            one_units = one_units.strip
#            if !one_units.empty?
#              LoincUnit.create!(
#                :loinc_item_id => loinc_item.id,
#                :loinc_num => loinc_item.loinc_num,
#                :unit => one_units,
#                :source_type => 'PHENX',
#                :source_id => 7
#              )
#            end
#          end
#        end
#
#      # update names. necessary
#      else
#        loinc_item.shortname = item.SHORTNAME if !item.SHORTNAME.nil?
#        loinc_item.phr_display_name = item.CONSUMER_NAME if loinc_item.phr_display_name.nil?
#        loinc_item.long_common_name = item.LONG_COMMON_NAME if !item.LONG_COMMON_NAME.nil?
#        loinc_item.example_units = item.EXAMPLE_UNITS if !item.EXAMPLE_UNITS.nil?
#        loinc_item.save!
#        # update loinc_units
#        if !loinc_item.example_units.nil? && !loinc_item.example_units.empty?
#          units_list = loinc_item.example_units.split(';')
#          if units_list.length > 0
#            LoincUnit.destroy_all(:loinc_item_id=>loinc_item.id)
#          end
#          units_list.each do | one_units|
#            one_units = one_units.strip
#            if !one_units.empty?
#              LoincUnit.create!(
#                :loinc_item_id => loinc_item.id,
#                :loinc_num => loinc_item.loinc_num,
#                :unit => one_units
#              )
#            end
#          end
#        end
#
#      end
#    end
#  end
#
#  # a mess in spreedsheet. do it manually
#  def self.phenx_answer_list
#    list_id = self.phenx_answer_list_create('54119-3')
#    loinc_item = LoincItem.find_by_loinc_num('54134-2')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#    loinc_item = LoincItem.find_by_loinc_num('56091-2')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#
#    loinc_item = LoincItem.find_by_loinc_num('56051-6')
#    loinc_item.answerlist_id = 624
#    loinc_item.save!
#
#    list_id = self.phenx_answer_list_create('56057-3')
#
#    list_id = self.phenx_answer_list_create('56090-4')
#
#    list_id = self.phenx_answer_list_create('56095-3')
#
#    list_id = self.phenx_answer_list_create('56097-9')
#    loinc_item = LoincItem.find_by_loinc_num('56098-7')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#    loinc_item = LoincItem.find_by_loinc_num('56099-5')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#    loinc_item = LoincItem.find_by_loinc_num('56100-1')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#
#    list_id = self.phenx_answer_list_create('56102-7')
#    loinc_item = LoincItem.find_by_loinc_num('56103-5')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#    loinc_item = LoincItem.find_by_loinc_num('56104-3')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#    loinc_item = LoincItem.find_by_loinc_num('56105-0')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#    loinc_item = LoincItem.find_by_loinc_num('56106-8')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#    loinc_item = LoincItem.find_by_loinc_num('56107-6')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#    loinc_item = LoincItem.find_by_loinc_num('56108-4')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#    loinc_item = LoincItem.find_by_loinc_num('56109-2')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#    loinc_item = LoincItem.find_by_loinc_num('56110-0')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#    loinc_item = LoincItem.find_by_loinc_num('56111-8')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#    loinc_item = LoincItem.find_by_loinc_num('56112-6')
#    loinc_item.answerlist_id = list_id
#    loinc_item.save!
#
#  end
#
#  def self.phenx_answer_list_create(loinc_num)
#    answers = TestPhenxAnswer.where(LOINC_NUM: loinc_num)
#    list_rec = AnswerList.create!(
#      :list_desc =>'new list that will appear in june 2009 release of Loinc'
#    )
#    answers.each do | answer |
#      # create answers records
#      answer_rec = Answer.create!(
#        :answer_text => answer.DISPLAY_TEXT
#      )
#      # create list_answers records
#      answer_code = answer.ANSWER_CODE.nil? ? answer.ANSWER_STRING_ID : answer.ANSWER_CODE
#      ListAnswer.create!(
#        :answer_list_id => list_rec.id,
#        :answer_id => answer_rec.id,
#        :code => answer_code,
#        :sequence_num => answer.SEQUENCE.to_i
#      )
#    end
#    puts "loinc_num : " + loinc_num
#    loinc_item = LoincItem.find_by_loinc_num(loinc_num)
#    loinc_item.answerlist_id = list_rec.id
#    loinc_item.save!
#
#    return list_rec.id
#  end
#
#  def self.phenx_panel_form
#    top_panel_item = LoincItem.find_by_loinc_num('56088-8')
#    top_panel_item.is_panel = true
#    top_panel_item.has_top_level_panel = true
#    top_panel_item.save!
#
#    toppanel = LoincPanel.create!(
#      :loinc_item_id => top_panel_item.id,
#      :loinc_num => top_panel_item.loinc_num,
#      :sequence_num => 0,
#      :observation_required_in_panel => 'R',
#      :observation_required_in_phr => 'R',
#      :answer_required => false,
#      :type_of_entry => 'Q',
#      :default_value => nil
#    )
#    toppanel.p_id = toppanel.id
#    toppanel.save!
#
#    # sub panels and tests
#    panelitems = TestPhenxForm.where("LOINC_NUM <> '56088-8' and PARENT_LOINC =?", top_panel_item.loinc_num)
#
#    if !panelitems.nil? && panelitems.length>0
#      panelitems.each do |panelitem|
#        self.copy_a_phenx_test(panelitem, toppanel)
#      end
#    end
#  end
#
#  def self.copy_a_phenx_test(item, parent)
#
#    loinc_item = LoincItem.find_by_loinc_num(item.LOINC_NUM)
#    if item.ROOT == 'PANEL'
#      loinc_item.is_panel = true
#      loinc_item.save!
#    end
#    test = LoincPanel.create!(
#      :loinc_item_id => loinc_item.id,
#      :loinc_num => item.LOINC_NUM,
#      :sequence_num => item.SEQUENCE.to_i,
#      :observation_required_in_panel => 'R',
#      :observation_required_in_phr => 'R',
#      :answer_required => false,
#      :type_of_entry => 'Q',
#      :default_value => nil,
#      :p_id => parent.id
#    )
#    # process sub items of the item
#    panelitems = TestPhenxForm.where("LOINC_NUM <> ? and PARENT_LOINC =?", item.LOINC_NUM, item.LOINC_NUM)
#
#    if !panelitems.nil? && panelitems.length>0
#      panelitems.each do |panelitem|
#        self.copy_a_phenx_test(panelitem, test)
#      end
#    end
#  end
#
#   def self.phenx_panel_form2
#
#    top_panels = TestPhenxForm.where(ROOT: 'PANEL')
#
#    top_panels.each do |top_panel|
#      panel_item = LoincItem.find_by_loinc_num(top_panel.LOINC_NUM)
#      panel_item.is_panel = true
#      panel_item.has_top_level_panel = true
#      panel_item.save!
#
#      toppanel = LoincPanel.create!(
#        :loinc_item_id => panel_item.id,
#        :loinc_num => panel_item.loinc_num,
#        :sequence_num => 0,
#        :observation_required_in_panel => 'R',
#        :observation_required_in_phr => 'R',
#        :answer_required => false,
#        :type_of_entry => 'Q',
#        :default_value => nil
#      )
#      toppanel.p_id = toppanel.id
#      toppanel.save!
#
#      # sub panels and tests
#      panelitems = TestPhenxForm.where("LOINC_NUM <> PARENT_LOINC and PARENT_LOINC =?", panel_item.loinc_num)
#
#      if !panelitems.nil? && panelitems.length>0
#        panelitems.each do |panelitem|
#          self.copy_a_phenx_test2(panelitem, toppanel)
#        end
#      end
#
#    end
#  end
#
#  def self.copy_a_phenx_test2(item, parent)
#
#    loinc_item = LoincItem.find_by_loinc_num(item.LOINC_NUM)
#    if item.ROOT == 'PANEL'
#      loinc_item.is_panel = true
#      loinc_item.save!
#    end
#    test = LoincPanel.create!(
#      :loinc_item_id => loinc_item.id,
#      :loinc_num => item.LOINC_NUM,
#      :sequence_num => item.SEQUENCE.to_i,
#      :observation_required_in_panel => 'R',
#      :observation_required_in_phr => 'R',
#      :answer_required => false,
#      :type_of_entry => 'Q',
#      :default_value => nil,
#      :p_id => parent.id
#    )
#    # process sub items of the item
#    panelitems = TestPhenxForm.where("LOINC_NUM <> ? and PARENT_LOINC =?", item.LOINC_NUM, item.LOINC_NUM)
#
#    if !panelitems.nil? && panelitems.length>0
#      panelitems.each do |panelitem|
#        self.copy_a_phenx_test2(panelitem, test)
#      end
#    end
#  end


  # 4/13/2010
  # convert those test/screening groups in the preventive group on the PHR form
  # into panels, with fake loinc_nums as X0001-1, X0002-1 and etc.
  def self.convert_screening_tests_to_panels
    # pap test
    loinc_item_panel = LoincItem.create!(
      :loinc_num => 'X0001-1',
      :component => 'Pap Test',
      :is_panel => true,
      :has_top_level_panel => true,
      :excluded_from_phr => false,
      :phr_display_name => 'Pap Test'
    )
    loinc_panel_p = LoincPanel.create!(
      :loinc_item_id => loinc_item_panel.id,
      :loinc_num => "X0001-1",
      :sequence_num => 1
    )
    loinc_panel_p.p_id = loinc_panel_p.id
    loinc_panel_p.save!
    loinc_item_test = LoincItem.create!(
      :loinc_num => 'X0002-1',
      :component => 'Pap Test Result',
      :is_panel => false,
      :has_top_level_panel => false,
      :excluded_from_phr => false,
      :phr_display_name => 'Pap Test Result'
    )
    LoincPanel.create!(
      :p_id => loinc_panel_p.id,
      :loinc_item_id => loinc_item_test.id,
      :loinc_num => "X0002-1",
      :sequence_num => 2,
      :observation_required_in_panel => 'R',
      :type_of_entry => 'Q',
      :observation_required_in_phr => 'R'
    )

    # abdominal ultrasound
    loinc_item_panel = LoincItem.create!(
      :loinc_num => 'X0003-1',
      :component => 'Abdominal Ultrasound',
      :is_panel => true,
      :has_top_level_panel => true,
      :excluded_from_phr => false,
      :phr_display_name => 'Abdominal Ultrasound'
    )
    loinc_panel_p = LoincPanel.create!(
      :loinc_item_id => loinc_item_panel.id,
      :loinc_num => "X0003-1",
      :sequence_num => 1
    )
    loinc_panel_p.p_id = loinc_panel_p.id
    loinc_panel_p.save!
    loinc_item_test = LoincItem.create!(
      :loinc_num => 'X0004-1',
      :component => 'Abdominal Ultrasound Result',
      :is_panel => false,
      :has_top_level_panel => false,
      :excluded_from_phr => false,
      :phr_display_name => 'Abdominal Ultrasound Result'
    )
    LoincPanel.create!(
      :p_id => loinc_panel_p.id,
      :loinc_item_id => loinc_item_test.id,
      :loinc_num => "X0004-1",
      :sequence_num => 2,
      :observation_required_in_panel => 'R',
      :type_of_entry => 'Q',
      :observation_required_in_phr => 'R'
    )

    # mammogram
    loinc_item_panel = LoincItem.create!(
      :loinc_num => 'X0005-1',
      :component => 'Mammogram',
      :is_panel => true,
      :has_top_level_panel => true,
      :excluded_from_phr => false,
      :phr_display_name => 'Mammogram'
    )
    loinc_panel_p = LoincPanel.create!(
      :loinc_item_id => loinc_item_panel.id,
      :loinc_num => "X0005-1",
      :sequence_num => 1
    )
    loinc_panel_p.p_id = loinc_panel_p.id
    loinc_panel_p.save!
    loinc_item_test = LoincItem.create!(
      :loinc_num => 'X0006-1',
      :component => 'Mammogram Result',
      :is_panel => false,
      :has_top_level_panel => false,
      :excluded_from_phr => false,
      :phr_display_name => 'Mammogram Result'
    )
    LoincPanel.create!(
      :p_id => loinc_panel_p.id,
      :loinc_item_id => loinc_item_test.id,
      :loinc_num => "X0006-1",
      :sequence_num => 2,
      :observation_required_in_panel => 'R',
      :type_of_entry => 'Q',
      :observation_required_in_phr => 'R'
    )

    # colon cancer screen panel with 3 tests
    #    fecal occult blood test (fobt)
    #    colonoscopy
    #    sigmoidoscopy
    loinc_item_panel = LoincItem.create!(
      :loinc_num => 'X0007-1',
      :component => 'Colon Cancer Screening',
      :is_panel => true,
      :has_top_level_panel => true,
      :excluded_from_phr => false,
      :phr_display_name => 'Colon Cancer Screening'
    )
    loinc_panel_p = LoincPanel.create!(
      :loinc_item_id => loinc_item_panel.id,
      :loinc_num => "X0007-1",
      :sequence_num => 1
    )
    loinc_panel_p.p_id = loinc_panel_p.id
    loinc_panel_p.save!
    # fecal
    loinc_item_test = LoincItem.create!(
      :loinc_num => 'X0008-1',
      :component => 'Fecal Occult Blood Test (FOBT)',
      :is_panel => false,
      :has_top_level_panel => false,
      :excluded_from_phr => false,
      :phr_display_name => 'Fecal Occult Blood Test (FOBT)'
    )
    LoincPanel.create!(
      :p_id => loinc_panel_p.id,
      :loinc_item_id => loinc_item_test.id,
      :loinc_num => "X0008-1",
      :sequence_num => 2,
      :observation_required_in_panel => 'R',
      :type_of_entry => 'Q',
      :observation_required_in_phr => 'R'
    )
    # colonoscopy
    loinc_item_test = LoincItem.create!(
      :loinc_num => 'X0009-1',
      :component => 'Colonoscopy',
      :is_panel => false,
      :has_top_level_panel => false,
      :excluded_from_phr => false,
      :phr_display_name => 'Colonoscopy'
    )
    LoincPanel.create!(
      :p_id => loinc_panel_p.id,
      :loinc_item_id => loinc_item_test.id,
      :loinc_num => "X0009-1",
      :sequence_num => 3,
      :observation_required_in_panel => 'R',
      :type_of_entry => 'Q',
      :observation_required_in_phr => 'R'
    )

    # sigmoidoscopy
    loinc_item_test = LoincItem.create!(
      :loinc_num => 'X0010-1',
      :component => 'Sigmoidoscopy',
      :is_panel => false,
      :has_top_level_panel => false,
      :excluded_from_phr => false,
      :phr_display_name => 'Sigmoidoscopy'
    )
    LoincPanel.create!(
      :p_id => loinc_panel_p.id,
      :loinc_item_id => loinc_item_test.id,
      :loinc_num => "X0010-1",
      :sequence_num => 4,
      :observation_required_in_panel => 'R',
      :type_of_entry => 'Q',
      :observation_required_in_phr => 'R'
    )

#    # update the panel field on phr form
#    form = Form.find_by_form_name('phr')
#    field = FieldDescription.find_by_form_id_and_target_field(form.id,'tp_temp_placeholder')
#    field.control_type_detail ='panel_name=>loinc_panel_temp,loinc_num=>(55417-0,55418-8,24331-1,53764-7,X0001-1,X0003-1,X0005-1,X0007-1)'
#    field.save!


    # copy over answer list
    # pap
    # Pap Test Results , 27
    text_list = TextList.find_by_list_name("Pap Test Results")
    text_items = TextListItem.where(text_list_id: text_list.id)

    answer_list= AnswerList.create!(
      :list_name=>text_list.list_name,
      :list_desc=>text_list.list_description,
      :code_system=>text_list.code_system
    )
    text_items.each do |text_item|
      answer = Answer.create!(
        :answer_text => text_item.item_text
      )
      ListAnswer.create!(
        :answer_list_id=>answer_list.id,
        :answer_id=>answer.id,
        :code=>text_item.code,
        :sequence_num=>text_item.sequence_num
      )
    end
    loinc_item = LoincItem.find_by_loinc_num('X0002-1')
    loinc_item.answerlist_id = answer_list.id
    loinc_item.save!

    # mammogram
    # Mammography Results, 28
    text_list = TextList.find_by_list_name("Mammography Results")
    text_items = TextListItem.where(text_list_id: text_list.id)
    answer_list= AnswerList.create!(
      :list_name=>text_list.list_name,
      :list_desc=>text_list.list_description,
      :code_system=>text_list.code_system
    )
    text_items.each do |text_item|
      answer = Answer.create!(
        :answer_text => text_item.item_text
      )
      ListAnswer.create!(
        :answer_list_id=>answer_list.id,
        :answer_id=>answer.id,
        :code=>text_item.code,
        :sequence_num=>text_item.sequence_num
      )
    end
    loinc_item = LoincItem.find_by_loinc_num('X0006-1')
    loinc_item.answerlist_id = answer_list.id
    loinc_item.save!

    # colonoscopy
    # Colonoscopy Results, 29
    text_list = TextList.find_by_list_name("Colonoscopy Results")
    text_items = TextListItem.where(text_list_id: text_list.id)
    answer_list= AnswerList.create!(
      :list_name=>text_list.list_name,
      :list_desc=>text_list.list_description,
      :code_system=>text_list.code_system
    )
    text_items.each do |text_item|
      answer = Answer.create!(
        :answer_text => text_item.item_text
      )
      ListAnswer.create!(
        :answer_list_id=>answer_list.id,
        :answer_id=>answer.id,
        :code=>text_item.code,
        :sequence_num=>text_item.sequence_num
      )
    end
    loinc_item = LoincItem.find_by_loinc_num('X0009-1')
    loinc_item.answerlist_id = answer_list.id
    loinc_item.save!
    # sigmoidoscopy
    # Colonoscopy Results, 29
    loinc_item = LoincItem.find_by_loinc_num('X0010-1')
    loinc_item.answerlist_id = answer_list.id
    loinc_item.save!
  end



  # 6/29/2010
  # Add Loinc panel 38269-7 (bone density) to the list of panels the user can
  # pick from, and give it a title of "Bone Density Study (DEXA)".
  def self.include_a_panel
    loinc_item = LoincItem.find_by_loinc_num('38269-7')
    loinc_item.excluded_from_phr = false
    loinc_item.phr_display_name = "Bone Density Study (DEXA)"
    loinc_item.save!

  end




  # 7/27/2010
  # moved smoke and high bp treatment our of risk factors group and created
  # a panel for them.
  def self.create_risk_factor_panel
    # create a risk factor panel
    loinc_item_panel = LoincItem.create!(
      :loinc_num => 'X0020-1',
      :component => 'Risk Factors',
      :is_panel => true,
      :has_top_level_panel => true,
      :excluded_from_phr => false,
      :included_in_phr => true,
      :phr_display_name => 'Risk Factors'
    )
    loinc_panel_p = LoincPanel.create!(
      :loinc_item_id => loinc_item_panel.id,
      :loinc_num => "X0020-1",
      :sequence_num => 1
    )
    loinc_panel_p.p_id = loinc_panel_p.id
    loinc_panel_p.save!
    # smoke
    loinc_item_test = LoincItem.create!(
      :loinc_num => 'X0021-1',
      :component => 'Smoked in last year?',
      :is_panel => false,
      :has_top_level_panel => false,
      :excluded_from_phr => false,
      :included_in_phr => true,
      :answerlist_id =>361,
      :datatype => 'CWE',
      :phr_display_name => 'Smoked in last year?'
    )
    LoincPanel.create!(
      :p_id => loinc_panel_p.id,
      :loinc_item_id => loinc_item_test.id,
      :loinc_num => "X0021-1",
      :sequence_num => 2,
      :observation_required_in_panel => 'R',
      :type_of_entry => 'Q',
      :observation_required_in_phr => 'R'
    )
    # high pressure
    loinc_item_test = LoincItem.create!(
      :loinc_num => 'X0022-1',
      :component => 'On treatment for high blood pressure?',
      :is_panel => false,
      :has_top_level_panel => false,
      :excluded_from_phr => false,
      :included_in_phr => true,
      :answerlist_id =>361,
      :datatype => 'CWE',
      :phr_display_name => 'On treatment for high blood pressure?'
    )
    LoincPanel.create!(
      :p_id => loinc_panel_p.id,
      :loinc_item_id => loinc_item_test.id,
      :loinc_num => "X0022-1",
      :sequence_num => 3,
      :observation_required_in_panel => 'R',
      :type_of_entry => 'Q',
      :observation_required_in_phr => 'R'
    )

  end


  #/11/34/2010
  # update loinc names using the included_in_phr flag
  # note: 4/2/2011.
  # this function is not correct under current situations
  # a test is included in phr does not mean it is seachable
  # i.e. inlcuded_in_phr=1 does not mean it is in LoincName table
  # NOTE: 11/1/2012, use LoincName.update_myself instead
  def self.update_loinc_names_new
    
    LoincName.delete_all

    selected_items = LoincItem.where(included_in_phr: true)

    selected_items.each do |item|
      if item.is_panel?
        type = "Panel"
        code = "P"
      else
        type = "Test"
        code = 'T'
      end
      # create a record,
      LoincName.create!(
        :loinc_num => item.loinc_num,
        :loinc_num_w_type => code + ':' + item.loinc_num,
        :display_name => item.display_name,
        :display_name_w_type => item.display_name + " (#{type})",
        :type_code => code,
        :type_name => type,
        :component => item.component,
        :short_name => item.shortname,
        :long_common_name => item.long_common_name,
        :related_names => item.relatednames2,
        :consumer_name => item.consumer_name
      )
    end

  end


  # 10/22/2010
  # recreate records in loinc_names from the records in loinc_items
  # NOTE: 11/1/2012, use LoincName.update_myself instead
  def self.update_loinc_names
    @tests_added = {}
    # clear all records in loinc_names
    LoincName.delete_all

    phr_top_level_panel_loinc_items = LoincItem.where("excluded_from_phr=? and is_panel=? and has_top_level_panel=?",
      false, true, true)
    phr_top_level_panel_loinc_items.each do |panel_loinc_item|
      loinc_panel = LoincPanel.find_by_loinc_num(panel_loinc_item.loinc_num,
          :conditions=>["id=p_id"])
      # panel itself, without tests
      type = 'Panel'
      code = 'P'
      LoincName.create!(
        :loinc_num => panel_loinc_item.loinc_num,
        :loinc_num_w_type => code + ':' + panel_loinc_item.loinc_num,
        :display_name => panel_loinc_item.display_name,
        :type_code => code,
        :type_name => type,
        :component => panel_loinc_item.component,
        :short_name => panel_loinc_item.shortname,
        :long_common_name => panel_loinc_item.long_common_name,
        :related_names => panel_loinc_item.relatednames2,
        :consumer_name => panel_loinc_item.consumer_name
      )
      @tests_added[panel_loinc_item.loinc_num] = true
      if loinc_panel.has_sub_fields?
        sub_fields = loinc_panel.subFields_old
        self.loop_through_panel(sub_fields)
      end
    end

  end

  def self.loop_through_panel(fields)
    fields.each do |field|
      if field.p_id != field.id
        if field.has_sub_fields?
          sub_fields = field.subFields_old
          self.loop_through_panel(sub_fields)
        else
          if !@tests_added[field.loinc_num]
            if field.loinc_item.is_panel?
              type = 'Panel'
              code = 'P'
            else
              type = 'Test'
              code = 'T'
            end
            # create a record,
            LoincName.create!(
              :loinc_num => field.loinc_num,
              :loinc_num_w_type => code + ':' + field.loinc_num,
              :display_name => field.loinc_item.display_name,
              :type_code => code,
              :type_name => type,
              :component => field.loinc_item.component,
              :short_name => field.loinc_item.shortname,
              :long_common_name => field.loinc_item.long_common_name,
              :related_names => field.loinc_item.relatednames2,
              :consumer_name => field.loinc_item.consumer_name
            )
            @tests_added[field.loinc_num] = true
          end
        end
      end
    end
  end

  # update panel classes
  # 10/25/2010
  def self.update_panel_selection_and_classes
#E: panel 56053-2 is not defined in loinc_panels
#E: panel 56055-7 is not defined in loinc_panels
#E: panel 56049-0 is not defined in loinc_panels
#E: panel 56062-3 is not defined in loinc_panels
#E: panel 56060-7 is not defined in loinc_panels
#E: panel 56059-9 is not defined in loinc_panels
#E: panel 56073-0 is not defined in loinc_panels
#E: panel 56054-0 is not defined in loinc_panels
#E: panel 56071-4 is not defined in loinc_panels
#E: panel 56085-4 is not defined in loinc_panels
#E: panel 56064-9 is not defined in loinc_panels
#E: panel 56058-1 is not defined in loinc_panels
#E: panel 56052-4 is not defined in loinc_panels
#E: panel 56075-5 is not defined in loinc_panels
#E: panel 56050-8 is not defined in loinc_panels
#E: panel 56082-1 is not defined in loinc_panels
#E: panel 56067-2 is not defined in loinc_panels
#E: panel 56084-7 is not defined in loinc_panels

    Form.transaction do

      # add new panel classes from file
      classPanels = {}
      itemToRemove = {}
      itemIsPanel = {}
      itemIsTest = {}
      File.open('/proj/defExtra/PanelClasses.csv') do |f|
        while (next_line = f.gets)
          sn, pName, pLoincNum, pClass, toRemove, isPanel = next_line.chomp.split(',')
          if pLoincNum != 'new' && !pLoincNum.match(/\A\?/) && pLoincNum != ''
            # to be removed
            if toRemove == 'x'
              itemToRemove[pLoincNum] = true
            # to add classes
            else
              # check if it is a panel or test
              if isPanel == 'x'
                itemIsPanel[pLoincNum] = true
              else
                itemIsTest[pLoincNum] = true
              end
              
              panelsInClass = classPanels[pClass]
              if panelsInClass.nil?
                panelsInClass = [pLoincNum]
              else
                panelsInClass << pLoincNum
              end
              classPanels[pClass] = panelsInClass
            end
          end
        end
      end

      # validate loinc nums in the file
      # a panel is a panel
      puts "validating panels"
      itemIsPanel.keys.each do |key|
        item = LoincItem.find_by_loinc_num(key)
        if item.nil?
          puts "W: #{key} is not found"
        else
          if !item.is_panel?
            puts "W: #{key} is not a panel"
          end
          if item.is_excluded?
            puts "W: #{key} is excluded"
          end
        end
      end
      # a test is a test
      puts "validating tests"
      itemIsTest.keys.each do |key|
        item = LoincItem.find_by_loinc_num(key)
        if item.nil?
          puts "W: #{key} is not found"
        else
          if !item.is_test?
            puts "W: #{key} is not a test"
          end
          if item.is_excluded?
            puts "W: #{key} is excluded"
          end
        end
      end
      # a panel is a panel
      puts "validating exclusion"
      itemToRemove.keys.each do |key|
        item = LoincItem.find_by_loinc_num(key)
        if item.nil?
          puts "W: #{key} is not found"
        else
          if item.is_excluded?
            puts "W: #{key} has already been excluded"
          end
        end
      end

      # to include those panels and tests in PHR
      itemIsPanel.keys.each do |key|
        item = LoincItem.find_by_loinc_num(key)
        if item.nil?
          puts "W: #{key} is not found"
        else
          item.included_in_phr = true
          item.save!
          # sub fields
          panel_item = LoincPanel.where("loinc_num=? and id=p_id", key).first
          if panel_item.nil?
            puts "E: panel #{key} is not defined in loinc_panels"
          else
            self.update_sub_fields(panel_item)
          end
        end
      end
      itemIsTest.keys.each do |key|
        item = LoincItem.find_by_loinc_num(key)
        if item.nil?
          puts "W: #{key} is not found"
        else
          item.included_in_phr = true
          item.save!
        end
      end


      # clean up the panel classes
      # Finds a class type named "Test Panel"
      ct = Classification.find_by_class_code("panel_class")

      # Destroys all class names
      ct.subclasses.map(&:destroy)
      
      # Creates class names and its class items
      index=1
      classPanels.each do |p_class_name, pLoincNums|
        # create class name
        cn = Classification.create!(
          :p_id => ct.id,
          :class_name => p_class_name,
          :class_code => index,
          :list_description_id => 1,
          :class_type_id => ct.id,
          :sequence => index)
        index +=1
        cn.save!

        pLoincNums.each_with_index do |item_code, index_ln|
          DataClass.create!(
            :classification_id => cn.id,
            :sequence => index_ln + 1,
            :item_code => item_code)
        end
      end
    end

  end

  def self.update_sub_fields(panel_field)
    sub_fields = panel_field.sub_fields
    sub_fields.each do |sub_field|
      if sub_field.id != sub_field.p_id
        sub_field.loinc_item.included_in_phr = true
        sub_field.loinc_item.save!
        update_sub_fields(sub_field)
      end
    end
  end

  #11/8/2010
  # add scores to answer list, from migration 728
  def self.add_scores
    Form.transaction do

      list = ['GCS_1','GCS_2','GCS_3',
        'PHQ-9',
        'Apgar_1','Apgar_2','Apgar_3','Apgar_4','Apgar_5',
        'DEEDS4.14','DEEDS4.15','DEEDS4.16',
        'FLACC-F','FLACC-L','FLACC-A','FLACC-Cr','FLACC-Co',
        'GDS_1','GDS_2',
        'BS_1','BS_2','BS_3','BS_4','BS_5','BS_6',
        'ECOG'] # list of answer lists with scores
      alist = AnswerList.where(list_name: list)
      alist.map{|e| e.update_attribute(:has_score, true)}

      alist.each do |ee|
        ee.list_answers.each do |e|
          e.update_attribute(:score, e.code) if e.code
        end
      end
    end
  end


  # 1/28/2011
  # add some normal ranges, delete empty units
  def self.add_or_change_units_ranges
    loinc_ranges_to_update_or_add = {
      # update
      '8480-6' => [['mm Hg', '90', '130']],
      '8462-4' => [['mm Hg', '60', '85']],
      '2744-1' => [[nil, '7.37', '7.47']],
      '2703-7' => [['mm Hg', '65', '80']],
      '2019-8' => [['mm Hg', '32', '43']],
      '1960-4' => [['mmol/L', '23', '28']],
      '1925-7' => [['mmol/L', '-2.5', '+2.5']],
      '26515-7' => [['k/cumm', '150', '450'],['/L', '150', '450'],['10*3/mm3', '150', '450']],
      '39156-5' => [['kg/m2', '18.5', '25']],
      '6768-6' => [['units/L', '45', '130']],
      '1742-6' => [['units/L', '7', '55']],
      '1920-8' => [['units/L', '8', '48']],
      # add
      '5811-5' => [[nil, '1.002', '1.030']],
      '5803-2' => [[nil, '5.0', '7.5']]
    }


    # cleanup units/ranges first
    # find those record that have ranges, 25 total
    ranges_to_parse=LoincUnit.where("norm_range like ?", "%:%")
    ranges_to_parse.each do |record|
      norm_range, unit = record.norm_range.split(":")
      # parse range
      if norm_range.match(/to/)
        low, high = norm_range.split('to')
      elsif norm_range.match(/-/)
        low, high = norm_range.split('-')
      else
        low, high = norm_range.split('<')
      end
      # check if unit has exist
      if unit == 'mmol.L'
        unit = 'mmol/L'
      end
      unit_record = LoincUnit.find_by_loinc_num_and_unit(record.loinc_num, unit)
      if unit_record.nil?
        # update itself
        record.unit = unit
        record.norm_range = norm_range
        record.norm_low = low
        record.norm_high = high
        puts "Update Self: #{record.loinc_num}, #{norm_range}, #{low}, #{high}"
        record.save!
        # update existing obx records
        str_sql = "update obx_observations set test_normal_high = '#{high}', test_normal_low= '#{low}' where loinc_num = '#{record.loinc_num}' and latest=1"
        ActiveRecord::Base.connection.execute(str_sql)

      else
        # delete itself and update the other record
        record.destroy
        unit_record.norm_range = norm_range
        unit_record.norm_high = high
        unit_record.norm_low = low
        puts "Delete & Update Other: #{record.loinc_num}, #{norm_range}, #{low}, #{high}"
        unit_record.save!
        # update existing obx records
        str_sql = "update obx_observations set test_normal_high = '#{high}', test_normal_low= '#{low}' where loinc_num = '#{unit_record.loinc_num}' and latest=1"
        ActiveRecord::Base.connection.execute(str_sql)
      end
    end

    # add or update more ranges
    loinc_ranges_to_update_or_add.each do |loinc_num, units_ranges|
      units_ranges.each do |unit_range|
        unit_record = LoincUnit.find_by_loinc_num_and_unit(loinc_num, unit_range[0])
        if unit_record.nil?
          # create a new one
          loinc_item = LoincItem.find_by_loinc_num(loinc_num)
          norm_range = unit_range[1] + ' - ' + unit_range[2]
          LoincUnit.create!(
            :loinc_item_id => loinc_item.id,
            :loinc_num => loinc_num,
            :unit => unit_range[0],
            :norm_range => norm_range,
            :norm_low => unit_range[1],
            :norm_high => unit_range[2]
          )
          puts "New: #{loinc_num}, #{unit_range[0]}, #{norm_range}"
          # update existing obx records
          str_sql = "update obx_observations set test_normal_high = '#{unit_range[2]}', test_normal_low= '#{unit_range[1]}' where loinc_num = '#{loinc_num}' and latest=1"
          ActiveRecord::Base.connection.execute(str_sql)
        else
          # update
          unit_record.norm_range = norm_range
          unit_record.norm_low = unit_range[1]
          unit_record.norm_high = unit_range[2]
          unit_record.save!
          puts "Update: #{loinc_num}, #{unit_range[0]}, #{norm_range}"
          # update existing obx records
          str_sql = "update obx_observations set test_normal_high = '#{unit_range[2]}', test_normal_low= '#{unit_range[1]}' where loinc_num = '#{loinc_num}' and latest=1"
          ActiveRecord::Base.connection.execute(str_sql)
        end
      end
    end
    
  end

  # 1/28/2011
  # make BMI a required test
  def self.make_bmi_required
    panel_items = LoincPanel.where(loinc_num: '39156-5')
    panel_items.each do |panel_item|
      panel_item.observation_required_in_phr = 'R'
      panel_item.save!
    end
  end

  #2/1/2011
  # recreate panel classes
  def self.recreate_panel_classes
    Form.transaction do
      # add new panel classes from file
      classPanels = {}
      itemChosen = []
      itemIsPanel = []
      itemIsTest = []
      itemExtra = []
      File.open('/proj/defExtra/panels_tests_0201.csv') do |f|
        while (next_line = f.gets)
          p_class, sub_class, chosen, type, level, loinc_num = next_line.chomp.split(',')

          # strip spaces
          type.strip! unless type.nil?
          p_class.strip! unless p_class.nil?
          sub_class.strip! unless sub_class.nil?
          chosen.strip! unless chosen.nil?
          level.strip! unless level.nil?
          loinc_num.strip! unless loinc_num.nil?
          # panel separator
          if type.match(/^===/)

          # panels/tests
          else
            # top level panel,
            if type.downcase == 'panel' && level == '1'  ||
                  chosen.downcase == 'y'

              if itemChosen.include?(loinc_num)
                itemExtra << loinc_num
              end
              itemChosen << loinc_num
              
              # classes
              panelsInClass = classPanels[p_class]
              if panelsInClass.nil?
                panelsInClass = [loinc_num]
              else
                panelsInClass << loinc_num
              end
              classPanels[p_class] = panelsInClass

              # check if it is a panel or test
              if type.downcase == 'panel'
                itemIsPanel << loinc_num
              else
                
                itemIsTest << loinc_num
              end
            end
          end
        end
      end

      testChosen = []
      File.open('/proj/defExtra/tests_only_0201.csv') do |f|
        while (next_line = f.gets)
          p_class, sub_class, loinc_num, name = next_line.chomp.split(',')

          # strip spaces
          p_class.strip! unless p_class.nil?
          sub_class.strip! unless sub_class.nil?
          loinc_num.strip! unless loinc_num.nil?

          testChosen << loinc_num
              
          # classes
          testsInClass = classPanels[p_class]
          if testsInClass.nil?
            testsInClass = [loinc_num]
          else
            testsInClass << loinc_num
          end
          classPanels[p_class] = testsInClass

          # create temp loinc items
          item = LoincItem.find_by_loinc_num(loinc_num)
          if item.nil?
            puts "W: #{loinc_num} is not found"
            puts "Createing a temp loinc item"
            LoincItem.create!(
              :loinc_num => loinc_num,
              :component => name,
              :datatype => nil,
              :phr_display_name => name,
              :is_panel => false,
              :has_top_level_panel => false,
              :excluded_from_phr => false,
              :included_in_phr => true
            )
          end

        end
      end

      # later decided to make these tests not searchable
      testNotSearchable = []
      File.open('/proj/defExtra/tests_not_searchable_0201.csv') do |f|
        while (next_line = f.gets)
          a,b,c, loinc_num = next_line.chomp.split(',')
          # strip spaces
          loinc_num.strip! unless loinc_num.nil?
          testNotSearchable << loinc_num
        end
      end

      # reset included flag
      LoincItem.update_all(:included_in_phr=> false)

      # validate loinc nums in the file
      puts "validating panels/tests"
      # to include those panels and tests in PHR
      (itemChosen+testChosen-testNotSearchable).uniq.each do |loinc_num|
        item = LoincItem.find_by_loinc_num(loinc_num)
        if item.nil?
          puts "W: #{loinc_num} is not found"
        else
          item.included_in_phr = true
          item.save!
          # sub fields
          if item.is_panel? && item.has_top_level_panel?
            panel_item = LoincPanel.where("loinc_num=? and id=p_id", loinc_num).first
            if panel_item.nil?
              puts "E: panel #{loinc_num} is not defined in loinc_panels"
            else
              self.update_sub_fields(panel_item)
            end
          end
        end
      end

      # recreate loinc_names data and index
      self.update_loinc_names_by_list((itemChosen+testChosen-testNotSearchable).uniq)

      # clean up the panel classes
      # Finds a class type named "Test Panel"
      ct = Classification.find_by_class_code("panel_class")

      # Destroys all class names
      ct.subclasses.map(&:destroy)
      
      # Creates class names and its class items
      index=1
      classPanels.each do |p_class_name, pLoincNums|
        # create class name
        cn = Classification.create!(
          :p_id => ct.id,
          :class_name => p_class_name,
          :class_code => index,
          :list_description_id => 1,
          :class_type_id => ct.id,
          :sequence => index)
        index +=1
        cn.save!

        (pLoincNums-testNotSearchable).uniq.each_with_index do |item_code, index_ln|
          DataClass.create!(
            :classification_id => cn.id,
            :sequence => index_ln + 1,
            :item_code => item_code)
        end
      end
    end
  end

  # 2/1/2011
  # update loinc names based on the list of loinc_nums
  def self.update_loinc_names_by_list(loinc_nums, update=true )

    if update
      LoincName.delete_all
    end
    

    loinc_nums.each do |loinc_num|
      
      item = LoincItem.find_by_loinc_num(loinc_num)
      if item.is_panel?
        type = "Panel"
        code = "P"
      else
        type = "Test"
        code = 'T'
      end
      # create a record,
      LoincName.create!(
        :loinc_num => item.loinc_num,
        :loinc_num_w_type => code + ':' + item.loinc_num,
        :display_name => item.display_name,
        :display_name_w_type => item.display_name + " (#{type})",
        :type_code => code,
        :type_name => type,
        :component => item.component,
        :short_name => item.shortname,
        :long_common_name => item.long_common_name,
        :related_names => item.relatednames2,
        :consumer_name => item.consumer_name
      )
    end

  end

  
  # 2/2/2011
  # user data modification for demo, on user Daisy Duck
  # not part of the LOINC preparation
  def self.modify_dd_data
    panels = {'24336-0' => 10,
              '34566-0' => 7,
              '24356-8' => 8,
              '24323-0' => 5
             }

    to_delete = ['24317-0']

    one_year_in_ms = 365 * 24 * 60 * 60 * 1000

    dd_profile_id = 3361

    ObrOrder.transaction do
      obr_records = ObrOrder.where("profile_id=? and latest=?", dd_profile_id, true)
      obr_records.each do |obr_record|
        date_et = obr_record.test_date_ET
        shift = panels[obr_record.loinc_num]

        if !shift.nil?
          new_test_date_et = shift * one_year_in_ms + date_et
          new_time = Time.at((new_test_date_et/1000).to_i)
          new_test_date = new_time.strftime("%Y %b %d")
          new_test_date_hl7 = new_time.strftime("%Y/%m/%d")
          #update obr
          obr_record.test_date = new_test_date
          obr_record.test_date_ET = new_test_date_et
          obr_record.test_date_HL7 = new_test_date_hl7
          obr_record.save!
          #update obx
          ObxObservation.update_all({:test_date=>new_test_date,:test_date_ET=>new_test_date_et,:test_date_HL7=>new_test_date_hl7},
              {:profile_id=>dd_profile_id, :latest=>true, :obr_order_id=>obr_record.id})
        end
      end


      # remove unwanted data
      to_delete.each do |loinc_num|
        obr_records = ObrOrder.where("profile_id=? and latest=? and loinc_num=?", dd_profile_id, true, loinc_num)

        obr_records.each do |obr_record|
          obr_record.latest = false
          obr_record.save!
          #update obx
          ObxObservation.update_all({:latest=>false},
              {:profile_id=>dd_profile_id, :latest=>true, :obr_order_id=>obr_record.id})
        end

      end
    end

  end

  #2/2/2011
  # add more data on Daisy Duck, for demo 
  def self.add_more_dd_data

    dd_profile_id=3361

    ObrOrder.transaction do
      File.open('/proj/defExtra/fake_dd_data.csv') do |f|
        # ignore the first line
        first_line = f.gets

        obr_order_id = nil
        obr_record_id = 600
        obx_record_id = 1
        while (next_line = f.gets)
          panel_loinc_num, test_loinc_num, value_code, timestamp, value, units, units_code, norm_high, norm_low, norm_range = next_line.chomp.split(',')

          # strip spaces
          panel_loinc_num.strip! unless panel_loinc_num.nil?
          test_loinc_num.strip! unless test_loinc_num.nil?
          value_code.strip! unless value_code.nil?
          timestamp.strip! unless timestamp.nil?
          value.strip! unless value.nil?
          units.strip! unless units.nil?
          units_code.strip! unless units_code.nil?
          norm_high.strip! unless norm_high.nil?
          norm_low.strip! unless norm_low.nil?
          norm_range.strip! unless norm_range.nil?

          # parse the timestamp
          t = timestamp.split()
          m, d, y = t[0].split('/')
          hr, min = t[1].split(':')
          if t[2].downcase == 'pm'
            hr = hr.to_i + 12
          end
          date_time =t[1] + " " + t[2]
          
          time = Time.local(y.to_i,m.to_i,d.to_i,hr.to_i,min.to_i,0)
          test_date_et = time.to_i * 1000
          test_date = time.strftime("%Y %b %d")
          test_date_hl7 = time.strftime("%Y/%m/%d")

          # has panel loinc num
          if !panel_loinc_num.blank?
            panel_loinc_item = LoincItem.find_by_loinc_num(panel_loinc_num)
            obr_record = ObrOrder.create!(
              :profile_id => dd_profile_id,
              :record_id => obr_record_id,
              :latest => true,
              :loinc_num => panel_loinc_num,
              :test_place => nil,
              :test_date => test_date,
              :test_date_ET => test_date_et,
              :test_date_HL7 => test_date_hl7,
              :created_by => 28,
              :panel_name => panel_loinc_item.display_name,
              :single_test => false,
              :test_date_time => date_time
            )
            obr_order_id = obr_record.id
            obr_record_id +=1
            obx_record_id =1
          end
          test_loinc_item = LoincItem.find_by_loinc_num(test_loinc_num)
          obx_record = ObxObservation.create!(
            :profile_id => dd_profile_id,
            :obr_order_id => obr_order_id,
            :record_id => obx_record_id,
            :latest => true,
            :loinc_num => test_loinc_num,
            :obx2_value_type => test_loinc_item.data_type,
            :obx3_2_obs_ident => test_loinc_item.display_name,
            :obx5_value => value,
            :obx5_1_value_if_coded => value_code,
            :obx6_1_unit => units,
            :unit_code => units_code,
            :obx7_reference_ranges => norm_range,
            :test_date => test_date,
            :test_date_ET => test_date_et,
            :test_date_HL7 => test_date_hl7,
            :test_normal_high => norm_high,
            :test_normal_low => norm_low,
            :required_in_panel => 'R',
            :created_by => 28
          )
          obx_record_id +=1
        end
      end
    end
  end

  # 2/4/2011
  # modify dd data
  # not part of the loinc preparation
  def self.modify_dd_data_one_panel
    panels = {'24336-0' => 10
             }

    one_year_in_ms = 365 * 24 * 60 * 60 * 1000

    dd_profile_id = 3361

    ObrOrder.transaction do
      obr_records = ObrOrder.where("profile_id=? and latest=?", dd_profile_id, true)
      obr_records.each do |obr_record|
        date_et = obr_record.test_date_ET
        shift = panels[obr_record.loinc_num]

        if !shift.nil?
          new_test_date_et = shift * one_year_in_ms + date_et
          new_time = Time.at((new_test_date_et/1000).to_i)
          new_test_date = new_time.strftime("%Y %b %d")
          new_test_date_hl7 = new_time.strftime("%Y/%m/%d")
          #update obr
          obr_record.test_date = new_test_date
          obr_record.test_date_ET = new_test_date_et
          obr_record.test_date_HL7 = new_test_date_hl7
          obr_record.save!
          #update obx
          ObxObservation.update_all({:test_date=>new_test_date,:test_date_ET=>new_test_date_et,:test_date_HL7=>new_test_date_hl7},
              {:profile_id=>dd_profile_id, :latest=>true, :obr_order_id=>obr_record.id})
        end
      end
    end

  end



  #2/4/2011
  # to make one panel and all its sub fields included in phr
  #
  # call update_loinc_names_new once the a panel is included
  def self.make_a_panel_included(loinc_num)
    panel_item = LoincPanel.where("loinc_num=? and id=p_id", loinc_num).first
    if panel_item.nil?
      puts "E: panel #{loinc_num} is not defined in loinc_panels"
    else
      panel_item.loinc_item.included_in_phr = true
      panel_item.loinc_item.save!
      self.update_sub_fields(panel_item)
    end

  end


  # 2/7/2011
  # modify dd data
  # not part of the loinc preparation
  def self.modify_dd_data_one_panel_2
    panels = {'24317-0' => 10
             }

    one_year_in_ms = 365 * 24 * 60 * 60 * 1000

    dd_profile_id = 3361

    ObrOrder.transaction do
      obr_records = ObrOrder.where("profile_id=? and latest=?", dd_profile_id, true)
      obr_records.each do |obr_record|
        date_et = obr_record.test_date_ET
        shift = panels[obr_record.loinc_num]

        if !shift.nil?
          new_test_date_et = shift * one_year_in_ms + date_et
          new_time = Time.at((new_test_date_et/1000).to_i)
          new_test_date = new_time.strftime("%Y %b %d")
          new_test_date_hl7 = new_time.strftime("%Y/%m/%d")
          #update obr
          obr_record.test_date = new_test_date
          obr_record.test_date_ET = new_test_date_et
          obr_record.test_date_HL7 = new_test_date_hl7
          obr_record.save!
          #update obx
          ObxObservation.update_all({:test_date=>new_test_date,:test_date_ET=>new_test_date_et,:test_date_HL7=>new_test_date_hl7},
              {:profile_id=>dd_profile_id, :latest=>true, :obr_order_id=>obr_record.id})
        end
      end
      

    end

  end

  #2/7/2011
  # fix some normal ranges
  def self.fix_some_ranges
    dd_profile_id = 3361
    ObrOrder.transaction do
      # update ranges for WBC 26464-8
      unit = LoincUnit.find_by_loinc_num_and_unit('26464-8', '/L')
      unit.norm_high ='11.3'
      unit.norm_low ='4.4'
      unit.save!
      unit = LoincUnit.find_by_loinc_num_and_unit('26464-8', '#/mm3')
      unit.norm_high ='11.3'
      unit.norm_low ='4.4'
      unit.norm_range= '4.4 - 11.3'
      unit.save!
      unit = LoincUnit.find_by_loinc_num_and_unit('26464-8', 'k/cumm')
      unit.norm_high ='11.3'
      unit.norm_low ='4.4'
      unit.save!

      ObxObservation.update_all({:obx7_reference_ranges=>'4.4-11.3 x10*9', :test_normal_high=>'11.3', :test_normal_low=>'4.4', :obx6_1_unit=>'/L', :unit_code=>'5752'},
          {:profile_id=>dd_profile_id, :latest=>true, :loinc_num=>'26464-8'})

      # remove range on weight 29463-7
      unit = LoincUnit.find_by_loinc_num_and_unit('29463-7', 'pounds')
      unit.norm_high = nil
      unit.norm_low =nil
      unit.norm_range= nil
      unit.save!
      
      ObxObservation.update_all({:obx7_reference_ranges=>nil, :test_normal_high=>nil, :test_normal_low=>nil},
          {:profile_id=>dd_profile_id, :latest=>true, :loinc_num=>'29463-7'})

    end
  end

  # 3/3/2011
  # replace some tests in the searchable list
  def self.replace_some_tests
    tests_to_remove = ['11540-2','11538-6','11539-4','18747-6','11541-0','18755-9','18758-3','18760-9']
    tests_to_add = {'41806-1'=>['Abdomen CT','Radiology - CT/MRI/nuclear medicine'],
                    '24627-2'=>['Chest CT','Radiology - CT/MRI/nuclear medicine'],
                    '24725-4'=>['Head CT','Radiology - CT/MRI/nuclear medicine'],
                    '25045-6'=>['Unspecified body region CT','Radiology - CT/MRI/nuclear medicine'],
                    '24590-2'=>['Brain MRI','Radiology - CT/MRI/nuclear medicine'],
                    '25056-3'=>['Unspecified body region MRI','Radiology - CT/MRI/nuclear medicine'],
                    '44136-0'=>['Unspecified body region PET','Radiology - CT/MRI/nuclear medicine'],
                    '25061-3'=>['Unspecified body region US','Radiology - plain film/ultrasound/barium']}
                  
    # updating classes is to be done on swdefd manually

    LoincItem.transaction do
      # remove some tests
      tests_to_remove.each do |loinc_num|
        loinc_item = LoincItem.find_by_loinc_num(loinc_num)
        if loinc_item.nil?
          puts "E: #{loinc_num} is not defined in loinc_items"
        else
          loinc_item.included_in_phr = false
          loinc_item.save!

          loinc_name = LoincName.find_by_loinc_num(loinc_num)
          loinc_name.destroy unless loinc_name.nil?
        end
      end

      # add some tests
      tests_to_add.each do |loinc_num, value|
        display_name = value[0]

        loinc_item = LoincItem.find_by_loinc_num(loinc_num)
        if loinc_item.nil?
          puts "E: #{loinc_num} is not defined in loinc_items"
        else
          loinc_item.included_in_phr = true
          loinc_item.phr_display_name = display_name
          loinc_item.save!

          if loinc_item.is_panel?
            type = "Panel"
            code = "P"
          else
            type = "Test"
            code = 'T'
          end
          # create a record,
          LoincName.create!(
            :loinc_num => loinc_item.loinc_num,
            :loinc_num_w_type => code + ':' + loinc_item.loinc_num,
            :display_name => loinc_item.display_name,
            :display_name_w_type => loinc_item.display_name + " (#{type})",
            :type_code => code,
            :type_name => type,
            :component => loinc_item.component,
            :short_name => loinc_item.shortname,
            :long_common_name => loinc_item.long_common_name,
            :related_names => loinc_item.relatednames2,
            :consumer_name => loinc_item.consumer_name
          )
        end
      end
    end # end of transaction
  end


  # 4/2/2011 additional answer lists for the sleep, meal panels
  # staring_list_id = 12000,
  # csv_file = '/proj/defExtra/answer_lists_04022011.csv'
  # split_by = ','
  # 8/20/2012, addition answer lists for newborn apgar score, developmental
  # milestones and seizure panels
  # staring_list_id = 12012,
  # csv_file = '/poj/defExtra/more/new_answer_list_08202012'
  # split_by = "\t"   # note: double quotes needed
  #
  def self.add_temp_answer_list(starting_answer_list_id, csv_file, split_by)

    AnswerList.transaction do
      File.open(csv_file) do |f|
        # ignore the first line
        first_line = f.gets

        while (next_line = f.gets)
          list_name, list_desc, code_system, answers = next_line.chomp.split(split_by)
          # strip spaces
          list_name.strip! unless list_name.nil?
          list_desc.strip! unless list_desc.nil?
          code_system.strip! unless code_system.nil?
          answers.strip! unless answers.nil?

          answer_array = answers.split(':').map do |x| x.strip end

          # create answer_lists record, id should start with 625
          list_rec = AnswerList.new
          list_rec.id = starting_answer_list_id
          list_rec.list_name = list_name
          list_rec.list_desc = list_desc
          list_rec.code_system = code_system
          list_rec.save!

          starting_answer_list_id += 1
          # create answers records, id should start with 10429
          # create list_answers records，id should start with 4528
          seq_num = 1
          answer_array.each do |answer|
            answer_rec = Answer.create!(
              :answer_text => answer
            )
            ListAnswer.create!(
              :answer_list_id => list_rec.id,
              :answer_id => answer_rec.id,
              :code => seq_num,
              :sequence_num => seq_num
            )
            seq_num += 1
          end
        end # end of while
      end # end of file
    end # end of transaction
  end


  # 4/2/2011 add some panels (sleep panels, meal log panels)
  # csv_file = '/proj/defExtra/sleep_panels_04022011.csv'
  # split_by = ','
  # 8/20/2012, newborn apgar score, developmental milestones and seizure panels
  # csv_file = '/proj/defExtra/more/new_panel_08202012.csv'
  # split_by = "\t"   # note: double quotes needed
  def self.add_temp_panels(csv_file, split_by)

    LoincItem.transaction do
      panel_loinc_nums = []
      File.open(csv_file) do |f|
        # ignore the first line
        first_line = f.gets

        while (next_line = f.gets)
          panel_loinc_num, panel_name, test_loinc_num, test_name, required, value_type, answer_list = next_line.chomp.split(split_by)
          # strip spaces
          panel_loinc_num.strip! unless panel_loinc_num.nil?
          panel_name.strip! unless panel_name.nil?
          test_loinc_num.strip! unless test_loinc_num.nil?
          
          test_name.strip! unless test_name.nil?
          required.strip! unless required.nil?
          value_type=value_type.strip.downcase unless value_type.nil?
          answer_list.strip! unless answer_list.nil?

          # find the answer_list_id
          answer_list_id = nil
          if !answer_list.blank?
            answer_list_id = AnswerList.find_by_list_name(answer_list).id
          end
          # data type
          data_type = nil
          hl7_v3_type = nil
          if !answer_list_id.nil?
            data_type = 'CWE'
            hl7_v3_type = 'CWE'
          elsif value_type == 'time'
            data_type = 'TS'
            hl7_v3_type = 'TS'
          elsif value_type == 'number'
            data_type = 'NM'
            hl7_v3_type = 'PQ'
          elsif value_type == 'free text'
            data_type = 'TX'
            hl7_v3_type = 'ED'
          end

          # it's a panel
          if !panel_loinc_num.blank?
            panel_loinc_nums << panel_loinc_num
            # create LoincItem record
            if panel_loinc_num.match('^X')
              loinc_item = LoincItem.create!(
                :loinc_num => panel_loinc_num,
                :component => panel_name,
                :datatype => data_type,
                :hl7_v3_type => hl7_v3_type,
                :answerlist_id => answer_list_id,
                :phr_display_name => panel_name,
                :is_panel => true,
                :has_top_level_panel => true,
                :included_in_phr => true,
                :is_searchable => true
              )
            else
              loinc_item = LoincItem.find_by_loinc_num(panel_loinc_num)
            end
            # create LoincPanel record
            panel_sn = 1
            top_panel = LoincPanel.create!(
              :loinc_item_id => loinc_item.id,
              :loinc_num => panel_loinc_num,
              :sequence_num => panel_sn,
              :observation_required_in_panel => required,
              :type_of_entry => nil,
              :observation_required_in_phr => required

            )
            top_panel.p_id = top_panel.id
            top_panel.save!
            panel_sn += 1

          # it's a test
          else
            # create LoincItem record
            if test_loinc_num.match('^X')
              loinc_item = LoincItem.create!(
                :loinc_num => test_loinc_num,
                :component => test_name,
                :datatype => data_type,
                :hl7_v3_type => hl7_v3_type,
                :answerlist_id => answer_list_id,
                :phr_display_name => test_name,
                :is_panel => false,
                :has_top_level_panel => false,
                :included_in_phr => true
              )
            else
              loinc_item = LoincItem.find_by_loinc_num(test_loinc_num)
            end
            # create LoincPanel record
            LoincPanel.create!(
              :p_id => top_panel.id,
              :loinc_item_id => loinc_item.id,
              :loinc_num => test_loinc_num,
              :sequence_num => panel_sn,
              :observation_required_in_panel => required,
              :type_of_entry => 'Q',
              :observation_required_in_phr => required
            )
            panel_sn +=1
          end

        end # end of while
      end # end of file

      # update LoincName
      LoincPreparation.update_loinc_names_by_list(panel_loinc_nums, false)
    end # end of transaction
  end


  # add a flag in the LoincItem table to indicate if it is searchable. i.e.
  # it is included in the LoincName table
  # Now it update LoincItem based on the records in LoincNames.
  # It should update in the other way around, from LoincItem to LoincName in the
  # future updates when a new LOINC data set is released and updated in the PHR
  # system
  # 4/2/2011
  def self.add_a_searchable_flag
    ActiveRecord::Base.connection.add_column :loinc_items, :is_searchable, :boolean, :default => false
    LoincItem.transaction do
      loinc_names = LoincName.all
      loinc_names.each do |loinc_name|
        loinc_item = LoincItem.find_by_loinc_num(loinc_name.loinc_num)
        loinc_item.is_searchable = true
        loinc_item.save!
      end
    end
  end

#
#  # Create answer code in the list_answers table for the use in the PHR project
#  # The original code is not unique and has many '-' or null value even for the
#  # answers in one answer list
#  # 4/15/2011
#  def self.create_phr_answer_code
#    ActiveRecord::Base.connection.add_column :list_answers, :answer_code, :string, :default => nil
#    ListAnswer.transaction do
#      answer_lists = AnswerList.all
#      answer_lists.each do |list|
#        answers = ListAnswer.all,
#            :conditions=>["answer_list_id =? ",list.id],
#            :order=>'answer_id')
#        answer_code = 1
#        answers.each do |answer|
#          answer.answer_code = answer_code.to_s
#          answer.save!
#          answer_code +=1
#        end
#      end
#    end
#  end


  # 4/28/2011
  # recreate panel classes to include subclass using the new classifications
  # and data_classes table
  def self.create_panel_classes_subclasses
    Form.transaction do
      selected_records = []

      searchable_items = LoincItem.where("included_in_phr=? and is_searchable=?", true, true)

      searchable_loinc_nums = searchable_items.map {|s| s.loinc_num }

      File.open('/proj/defExtra/more/panels_tests_0201.csv') do |f|
        while (next_line = f.gets)
          p_class, sub_class, chosen, type, level, loinc_num = next_line.chomp.split(',')

          # strip spaces
          type.strip! unless type.nil?
          p_class.strip! unless p_class.nil?
          sub_class.strip! unless sub_class.nil?
          chosen.strip! unless chosen.nil?
          level.strip! unless level.nil?
          loinc_num.strip! unless loinc_num.nil?
          # panel separator
          if type.match(/^===/)

          # panels/tests
          else
            # top level panel,
            if type.downcase == 'panel' && level == '1'  ||
                  chosen.downcase == 'y'

              if searchable_loinc_nums.include?(loinc_num)
                selected_records << [p_class, sub_class, loinc_num]
              end

            end
          end
        end
      end

      File.open('/proj/defExtra/more/tests_only_0201.csv') do |f|
        while (next_line = f.gets)
          p_class, sub_class, loinc_num, name = next_line.chomp.split(',')

          # strip spaces
          p_class.strip! unless p_class.nil?
          sub_class.strip! unless sub_class.nil?
          loinc_num.strip! unless loinc_num.nil?


          if searchable_loinc_nums.include?(loinc_num)
            selected_records << [p_class, sub_class, loinc_num]
          end

        end
      end

      # add classes/subclasses
      # re-organize selected_reocrds into a hash of hash
      # {p_class => {sub_class => [loinc_nums]}}

      # process classes
      class_hash = self.convert_2d_array_to_hash(selected_records)

      # process sub classes
      class_hash.each do |p_class, subclass_test|
        class_hash[p_class] = self.convert_2d_array_to_hash(subclass_test)
      end

      # print out result
      class_hash.each do |key, values|
        puts "Class          #{key}"
        values.each do |sub_key, sub_values|
          puts "  Sub-Class    #{sub_key}"
          sub_values.each do |v|
            puts "    Loinc Num: #{v[0]}"
          end
        end
      end

      # insert classes/subclass information into the classifications and
      # data_classes tables
      panel_root_rec = Classification.find_by_class_code('panel_class')

      panel_class_sn = 1
      class_hash.each do |key, values|
        panel_class_rec = Classification.create!(
          :class_name => key,
          :class_code => panel_class_sn, # code should be provided Swapna
          :sequence => panel_class_sn,
          :p_id => panel_root_rec.id
        )
        panel_class_sn +=1
        panel_subclass_sn = 1
        values.each do |sub_key, sub_values|
          # has sub classes
          if !sub_key.blank?
            panel_subclass_rec = Classification.create!(
              :class_name => sub_key,
              :class_code => panel_subclass_sn, # code should be provided Swapna
              :sequence => panel_subclass_sn,
              :p_id => panel_class_rec.id
            )
            panel_subclass_sn += 1
            class_rec_id = panel_subclass_rec.id
          # no subclass
          else
            class_rec_id = panel_class_rec.id
          end
          # add leaf node
          loinc_sn = 1
          sub_values.each do |v|
            loinc_item = LoincItem.find_by_loinc_num(v[0])
            if !loinc_item.nil?
              DataClass.create!(
                :data_item_type => 'loinc_items',
                :data_item_id => loinc_item.id,
                :name_method => 'display_name_w_type',
                :code_method => 'loinc_num',
                :sequence => loinc_sn,
                :classification_id => class_rec_id
              )
              loinc_sn +=1
            end
          end
        end
      end

      return ''

    end
  end


#  # 5/6/2011 an alternative method to work on the new classification table
#  # NOT USED
#  # recreate panel classes to include subclass using the new classifications
#  # and data_classes table
#  def self.create_panel_classes_subclasses_alt
#    Form.transaction do
#      selected_records = []
#
#      searchable_items = LoincItem.where("included_in_phr=? and is_searchable=?", true, true)
#
#      searchable_loinc_nums = searchable_items.map {|s| s.loinc_num }
#
#      File.open('/proj/defExtra/more/panels_tests_0201.csv') do |f|
#        while (next_line = f.gets)
#          p_class, sub_class, chosen, type, level, loinc_num = next_line.chomp.split(',')
#
#          # strip spaces
#          type.strip! unless type.nil?
#          p_class.strip! unless p_class.nil?
#          sub_class.strip! unless sub_class.nil?
#          chosen.strip! unless chosen.nil?
#          level.strip! unless level.nil?
#          loinc_num.strip! unless loinc_num.nil?
#          # panel separator
#          if type.match(/^===/)
#
#          # panels/tests
#          else
#            # top level panel,
#            if type.downcase == 'panel' && level == '1'  ||
#                  chosen.downcase == 'y'
#
#              if searchable_loinc_nums.include?(loinc_num)
#                selected_records << [p_class, sub_class, loinc_num]
#              end
#
#            end
#          end
#        end
#      end
#
#      File.open('/proj/defExtra/more/tests_only_0201.csv') do |f|
#        while (next_line = f.gets)
#          p_class, sub_class, loinc_num, name = next_line.chomp.split(',')
#
#          # strip spaces
#          p_class.strip! unless p_class.nil?
#          sub_class.strip! unless sub_class.nil?
#          loinc_num.strip! unless loinc_num.nil?
#
#
#          if searchable_loinc_nums.include?(loinc_num)
#            selected_records << [p_class, sub_class, loinc_num]
#          end
#
#        end
#      end
#
#      # add classes/subclasses
#      # re-organize selected_reocrds into a hash of hash
#      # {p_class => {sub_class => [loinc_nums]}}
#
#      # process classes
#      class_hash = self.convert_2d_array_to_hash(selected_records)
#
#      # process sub classes
#      class_hash.each do |p_class, subclass_test|
#        class_hash[p_class] = self.convert_2d_array_to_hash(subclass_test)
#      end
#
#      # print out result
#      class_hash.each do |key, values|
#        puts "Class          #{key}"
#        values.each do |sub_key, sub_values|
#          puts "  Sub-Class    #{sub_key}"
#          sub_values.each do |v|
#            puts "    Loinc Num: #{v[0]}"
#          end
#        end
#      end
#
#      # insert classes/subclass information into the classifications and
#      # data_classes tables
#      panel_root_rec = Classification.find_by_class_code('panel_class')
#
#      panel_class_sn = 1
#      class_hash.each do |key, values|
#        panel_class_rec = Classification.create!(
#          :class_name => key,
#          :class_code => panel_class_sn, # code should be provided by Swapna
#          :sequence => panel_class_sn,
#          :p_id => panel_root_rec.id
#        )
#        panel_class_sn +=1
#        panel_subclass_sn = 1
#        values.each do |sub_key, sub_values|
#          # has sub classes
#          if !sub_key.blank?
#            panel_subclass_rec = Classification.create!(
#              :class_name => sub_key,
#              :class_code => panel_subclass_sn, # code should be provided by Swapna
#              :sequence => panel_subclass_sn,
#              :p_id => panel_class_rec.id
#            )
#            panel_subclass_sn += 1
#            class_rec_id = panel_subclass_rec.id
#          # no subclass
#          else
#            class_rec_id = panel_class_rec.id
#          end
#          # add leaf node
#          loinc_sn = 1
#          sub_values.each do |v|
#            loinc_item = LoincItem.find_by_loinc_num(v[0])
#            if !loinc_item.nil?
#              Classification.create!(
#                :p_id=>class_rec_id,
#                :source_item_id => loinc_item.id,
#                :sequence => loinc_sn,
#                :class_code => loinc_item.loinc_num,
#                :class_name => loinc_item.display_name
#              )
#              loinc_sn +=1
#            end
#          end
#        end
#      end
#
#      return ''
#
#    end
#  end

  # 5/13/2011
  # recreate panel classes to include subclass using the new classifications
  # and data_classes table
  # NOTE: classifications table structure changed, this method does not work
  # any more, 11/1/2012
  def self.recreate_panel_classes_subclasses
    Form.transaction do
      selected_records = []

#      searchable_items = LoincItem.where("included_in_phr=? and is_searchable=?", true, true)
#
#      searchable_loinc_nums = searchable_items.map {|s| s.loinc_num }

      File.open('/proj/defExtra/more/test_panel_classes_subclasses_0513.csv') do |f|
        # ignore the first line
        first_line = f.gets
        
        while (next_line = f.gets)
          p_class, sub_class, type, level, loinc_num = next_line.chomp.split(',')

          # strip spaces
          type.strip! unless type.nil?
          p_class.strip! unless p_class.nil?
          sub_class.strip! unless sub_class.nil?
          level.strip! unless level.nil?
          loinc_num.strip! unless loinc_num.nil?
          # panel separator
          if p_class.match(/^===/)

          # panels/tests
          else
#              if searchable_loinc_nums.include?(loinc_num)
             selected_records << [p_class, sub_class, loinc_num]
#              end

          end
        end
      end

      # add classes/subclasses
      # re-organize selected_reocrds into a hash of hash
      # {p_class => {sub_class => [loinc_nums]}}

      # process classes
      class_hash = self.convert_2d_array_to_hash(selected_records)

      # process sub classes
      class_hash.each do |p_class, subclass_test|
        class_hash[p_class] = self.convert_2d_array_to_hash(subclass_test)
      end

      # print out result
      class_hash.each do |key, values|
        puts "Class          #{key}"
        values.each do |sub_key, sub_values|
          puts "  Sub-Class    #{sub_key}"
          sub_values.each do |v|
            puts "    Loinc Num: #{v[0]}"
          end
        end
      end


      # insert classes/subclass information into the classifications and
      # data_classes tables
      panel_root_rec = Classification.find_by_class_code('panel_class')
      if panel_root_rec.nil?
        # create a record for panel class
        panel_root_rec = Classification.create!(
          :class_name => 'Panel Classes',
          :class_code => 'panel_class',
          :sequence => 1,
          :p_id => nil,
          :item_master_model => 'LoincItem',
          :item_name_field => 'display_name',
          :item_code_field => 'loinc_num'
        )
      end

      panel_class_sn = 1
      class_hash.each do |key, values|
        panel_class_rec = Classification.create!(
          :class_name => key,
          :class_code => panel_class_sn, # code should be provided Swapna
          :sequence => panel_class_sn,
          :p_id => panel_root_rec.id,
          :item_master_model => 'LoincItem',
          :item_name_field => 'display_name',
          :item_code_field => 'loinc_num'
        )
        panel_class_sn +=1
        panel_subclass_sn = 1
        values.each do |sub_key, sub_values|
          # has sub classes
          if !sub_key.blank?
            panel_subclass_rec = Classification.create!(
              :class_name => sub_key,
              :class_code => panel_subclass_sn, # code should be provided Swapna
              :sequence => panel_subclass_sn,
              :p_id => panel_class_rec.id,
              :item_master_model => 'LoincItem',
              :item_name_field => 'display_name',
              :item_code_field => 'loinc_num'
            )
            panel_subclass_sn += 1
            class_rec_id = panel_subclass_rec.id
          # no subclass
          else
            class_rec_id = panel_class_rec.id
          end
          # add leaf node
          loinc_sn = 1
          sub_values.each do |v|
            loinc_item = LoincItem.find_by_loinc_num(v[0])
            if !loinc_item.nil?
              DataClass.create!(
                :item_id => loinc_item.id,
                :item_code => loinc_item.loinc_num,
                :sequence => loinc_sn,
                :classification_id => class_rec_id
              )
              loinc_sn +=1
            end
          end
        end
      end

      return ''

    end
  end


  # 10/31/2012
  # recreate panel classes/subclasses based on the file from Swapna
  def self.recreate_panel_classes_subclasses_2
    Form.transaction do
      selected_records = []

      #File.open('/proj/defExtra/more/test_panel_classes_subclasses_10262012.csv') do |f|
      CSV.foreach('/proj/defExtra/more/test_panel_classes_subclasses_10262012.csv',
          :headers =>:first_row,
          :header_converters=> :symbol) do |row|
        p_class = row[:class]
        class_seq = row[:class_sequence]
        sub_class = row[:subclass]
        subclass_seq = row[:subclass_sequence]
        phr_name = row[:phr_name]
        loinc_num = row[:loinc_num]
        loinc_seq = row[:loinc_sequence]

        # strip spaces
        p_class.strip! unless p_class.nil?
        sub_class.strip! unless sub_class.nil?
        phr_name.strip! unless phr_name.nil?
        loinc_num.strip! unless loinc_num.nil?
        class_seq.strip! unless class_seq.nil?
        subclass_seq.strip! unless subclass_seq.nil?
        loinc_seq.strip! unless loinc_seq.nil?

        selected_records << [p_class, sub_class, loinc_num, phr_name] #, class_seq, subclass_seq, loinc_seq]
                                                            # hash is ordered in ruby 1.9
      end

      # insert class and subclass on each row
      last_class = nil # selected_records[0][0]
      last_subclass = nil # selected_records[0][1]
      has_subclass = nil
      selected_records.each do |row|

        # new class
        if !row[0].nil?
          last_class = row[0]
          if row[1].blank?
            has_subclass = false
          else
            has_subclass = true
          end
        # same class
        else
          row[0] = last_class
        end

        # new sub class
        if has_subclass
          if !row[1].nil?
            last_subclass = row[1]
          # same sub class
          else
            row[1] = last_subclass
          end

        end
      end
      # add classes/subclasses
      # re-organize selected_reocrds into a hash of hash
      # {p_class => {sub_class => [loinc_nums]}}

      # process classes
      class_hash = self.convert_2d_array_to_hash(selected_records, false)

      # process sub classes
      class_hash.each do |p_class, subclass_test|
        class_hash[p_class] = self.convert_2d_array_to_hash(subclass_test, false)
      end

      # print out result
      class_hash.each do |key, values|
        puts "Class          #{key}"
        values.each do |sub_key, sub_values|
          puts "  Sub-Class    #{sub_key}"
          sub_values.each do |v|
            puts "    Loinc Num: #{v[0]}"
          end
        end
      end

      # delete existing test panel classes
      panel_root_rec = Classification.find_by_class_code('panel_class')
      Classification.where(p_id: panel_root_rec.id).each do | subclass_rec |
        subclass_rec.destroy
      end

      # insert classes/subclass information into the classifications and
      # data_classes tables
      panel_root_rec = Classification.find_by_class_code('panel_class')
      if panel_root_rec.nil?
        # create a record for panel class
        panel_root_rec = Classification.create!(
          :class_name => 'Panel Classes',
          :class_code => 'panel_class',
          :sequence => 1,
          :p_id => 109, # now it has a ROOT record
          :list_description_id => 1,
          :class_type_id => 1
        )
      end

      class_code = 1
      panel_class_sn = 1
      class_hash.each do |key, values|
        panel_class_rec = Classification.create!(
          :class_name => key,
          :class_code => class_code,
          :sequence => panel_class_sn,
          :p_id => panel_root_rec.id,
          :list_description_id => 1,
          :class_type_id => 1
        )
        class_code += 1
        panel_class_sn +=1
        panel_subclass_sn = 1
        values.each do |sub_key, sub_values|
          # has sub classes
          if !sub_key.blank?
            panel_subclass_rec = Classification.create!(
              :class_name => sub_key,
              :class_code => class_code,
              :sequence => panel_subclass_sn,
              :p_id => panel_class_rec.id,
              :list_description_id => 1,
              :class_type_id => 1
            )
            class_code += 1
            panel_subclass_sn += 1
            class_rec_id = panel_subclass_rec.id
          # no subclass
          else
            class_rec_id = panel_class_rec.id
          end
          # add leaf node
          loinc_sn = 1
          sub_values.each do |v|
            loinc_item = LoincItem.find_by_loinc_num(v[0])
            if !loinc_item.nil?
              DataClass.create!(
                :item_code => loinc_item.loinc_num,
                :sequence => loinc_sn,
                :classification_id => class_rec_id
              )
              loinc_sn +=1
#              if v[1] != loinc_item.phr_display_name
#                puts "#{loinc_item.loinc_num} : #{v[1]}  | #{loinc_item.phr_display_name}"
#              end
              # set is_included and is_searchable flag.
              loinc_item.is_searchable = true
              loinc_item.included_in_phr = true
              # update the phr_name
              loinc_item.phr_display_name = v[1]
              loinc_item.save!
              # set this panels all tests to be included
              if loinc_item.has_top_level_panel?
                panel_item = LoincPanel.where("loinc_num=? and p_id=id", loinc_item.loinc_num).first
                all_sub_fields = []
                if panel_item.nil?
                  puts "#{loinc_item.loinc_num} is not a panel"
                else
                  panel_item.get_all_sub_fields(all_sub_fields, false)
                  all_sub_fields.each do |sub_field|
                    sub_field.loinc_item.included_in_phr = true
                    sub_field.loinc_item.save!
                  end
                end
              end # end of panel

            else
              puts "#{v[0]}: #{v[1]} is not in database,  subclass: #{sub_key} "
            end # end of loinc_item
          end # end of leaf nodes
        end # end of sub classes
      end # end of classes

      return ''

    end
  end


  def self.convert_2d_array_to_hash(record_array, sort_array = true)

    if sort_array
      sorted_array = record_array.uniq.sort {|x,y| x[0] <=> y[0]}
    else
      sorted_array = record_array
    end
    
    # process first item
    hash = {}
    sub_hash = {}
    key = sorted_array[0][0]
    sorted_array.each do |record|
      if key == record[0]
        if sub_hash.empty?
          sub_hash[key] = [record[1..record.length]]
        else
          sub_hash[key] << record[1..record.length]
        end
      else
        hash.merge!(sub_hash)
        sub_hash = {}
        key=record[0]
        sub_hash[key] = [record[1..record.length]]
      end
    end
    # last one
    hash.merge!(sub_hash)

    return hash

  end

#  - As all the old classification tables have been removed, this method won't work
#    anymore -Frank 9/15/2011
#
#  # 5/12/2011 migrate all classes from the existing tables to the new
#  # classifications and data_classes tables
#  # excluding test panels
#  def self.migrate_all_classes_except_test_panel
#
#    # test panel not included
#    class_types = [['Problem','problem','GopherTerm','consumer_name', 'key_id'],
#        ['Drug','drug','DrugNameRoute','text','code'],
#        ['Drug Ingredient','drug_ingredient','RxtermsIngredient','name','ing_rxcui'],
#        ['Vaccine','vaccine','VaccineList','item_text','code']] # vaccine name /code???
#
#    Form.transaction do
#      # Finds a class type
#      class_ct = ClassManagementDescription["class_types"]
#
#      level_1_sn = 2  # 1 has been used by test panel
#      class_types.each do |class_type|
#        # old class type, (new class level 1)
#        class_type_record = class_ct.model.where(
#          "#{class_ct.foreign_key} = ? AND #{class_ct.name_field} like ?",
#           ClassManagementDescription.root.id, class_type[0]).first
#
#        class_level_1  = Classification.create!(
#            :class_name => class_type[0],
#            :class_code => class_type[1],
#            :sequence => level_1_sn,
#            :p_id => nil,
#            :item_master_model => class_type[2],
#            :item_name_field => class_type[3],
#            :item_code_field => class_type[4]
#          )
#        level_1_sn +=1
#
#        # old class name, (new class level 2)
#        level_2_sn = 1
#        class_cn = ClassManagementDescription["class_names"]
#        class_name_records = class_cn.model.where("#{class_cn.foreign_key} = ?", class_type_record.id)
#        class_name_records.each do |class_name_rec|
#          class_level_2 = Classification.create!(
#            :class_name => class_name_rec.item_text,
#            :class_code => class_name_rec.code,
#            :sequence => level_2_sn,
#            :p_id => class_level_1.id,
#            :item_master_model => class_type[2],
#            :item_name_field => class_type[3],
#            :item_code_field => class_type[4]
#          )
#          level_2_sn +=1
#
#          # leaf nodes
#          leaf_sn =1
#          data_items = ClassificationJoin.where("class_term_id=?", class_name_rec.id)
#          data_items.each do |data_item_rec|
#            DataClass.create!(
#                      :item_id => nil,
#                      :item_code => data_item_rec.class_item_code,
#                      :sequence => leaf_sn,
#                      :classification_id => class_level_2.id
#            )
#            leaf_sn +=1
#          end
#
#        end # end of class name (level 2)
#      end # end of class type (level 1)
#    end # end of transaction
#  end

  
  # 10/4/2011 remove normal ranges on weight and height. 
  # only find one currently has range
  def self.remove_weight_normal_range
    LoincUnit.transaction do
      unit = LoincUnit.find_by_loinc_num('3141-9')
      unit.norm_high = nil # 200
      unit.norm_low =nil   # 50
      unit.danger_high =nil#350
      unit.danger_low=nil  #50
      unit.save!       
    end
  end
  
  
  # 4/16/2012 bug fix for loinc_panel_special, where a wrong loinc_num for LDL
  # was used
  def self.loinc_panels_special_bug_fix
    # add phr_display_name and replace the orders of the tests for Lipid panel
    # Lipid
    Form.transaction do

        panel = LoincPanel.find_by_loinc_num('24331-1',:conditions=>"p_id=id")
        sub_fields = panel.subFields_old
        sub_fields.each do |sub_field|
          item = sub_field.loinc_item
          case sub_field.loinc_num
          when '2093-3'
            sub_field.sequence_num = 1
            item.phr_display_name = 'Cholesterol Total'
          when '2085-9'
            sub_field.sequence_num = 2
            item.phr_display_name = 'HDLc (Good Cholesterol)'
          when '13457-7'
            sub_field.sequence_num = 3        
            item.phr_display_name = 'LDLc (Bad Cholesterol)'
            # make the LDLc test required in the Lipid Panel
            sub_field.observation_required_in_phr = 'R'
          when '2571-8'
            sub_field.sequence_num = 4
            item.phr_display_name = 'Triglyceride'
          when '11054-4'
            sub_field.sequence_num = 5
            item.phr_display_name = nil
          when '13458-5'
            sub_field.sequence_num = 6
            item.phr_display_name = nil
          when '9830-1'
            sub_field.sequence_num = 7
            item.phr_display_name = 'Cholesterol/HDLc Ratio'
          end
          sub_field.save!
          item.save!
        end
        
        # fix ranges
        unit = LoincUnit.find_by_loinc_num('2571-8')
        unit.norm_range = '<150'
        unit.norm_high = 150
        unit.norm_low = 0
        unit.save!

    end
    
  end
  
  # 4/18/2011 temp method, to be removed  
  def self.test_zip
    require 'open3'
    report_string = File.read('test.cvs')

    password ='123'
    
    zipped_string = ''
    # If password is nil or blank be forgiving.  Be careful to use the array
    # form of the system command to prevent command injection attacks.
    cmd_parts = ['zip', '-j', '-q']
    cmd_parts.concat(['-P', password]) if !password.blank?
    
    Open3.popen3(cmd_parts.join(' ')) do | stdin, stdout, stderr |
      stdin.write report_string
      stdin.flush
      stdin.close
      zipped_string = stdout.read
      stdout.close
    end
    
    f = File.open('test.cvs.zip', 'w')
    f.write(zipped_string)
    f.close
    return zipped_string
    
#    
#  # Create a temp zip file.  Note that gzip is not supported by Windows,
#    # so the "zip" gem does not handle password protection yet, so we will
#    # have to use a Linux command to create the zip file.
#    tfile = Tempfile.new(['export', file_ext])
#    tfile.write(report_string)
#    tfile.close
#    dirname = File.dirname(tfile.path)
#    filename = File.basename(tfile.path)
#    zip_path_name = File.join(dirname, filename + '.zip')
#
#    # If password is nil or blank be forgiving.  Be careful to use the array
#    # form of the system command to prevent command injection attacks.
#    cmd_parts = ['zip', '-j', '-q']
#    cmd_parts.concat(['-P', password]) if !password.blank?
#    cmd_parts.concat([zip_path_name, tfile.path])
#    system(*cmd_parts)
#    tfile.delete # the original temporary file, not the zip file
#    return zip_path_name    
  end
  
  # 4/19/2012
  # fix bugs on loinc_units table where norm_range is null but either norm_high
  # or norm_low has values
  # 
  def self.create_normal_range_from_high_and_low
    LoincUnit.transaction do
      units = LoincUnit.where('(norm_range is null or norm_range="") and (norm_high is not null or norm_low is not null)')
      units.each do |unit|
        if !unit.norm_high.blank? 
          if !unit.norm_low.blank?
            norm_range = unit.norm_low + " - " + unit.norm_high 
          else
            norm_range = "< " + unit.norm_high 
          end
        elsif !unit.norm_low.blank?
            norm_range = "> " + unit.norm_low
        end
        unit.norm_range = norm_range
        unit.save!       
      end  
    end      
  end

  # 6/1/2012
  # copy the answer_string_id in the ANSWERS table of the LOINC dataset over
  # to the answers table as 'answer_string_id' and list_answers table as 'code'
  def self.update_answer_code
    ActiveRecord::Base.connection.add_column :answers, :answer_string_id, :string
    ActiveRecord::Base.connection.rename_column :list_answers, :code, :code_ref
    ActiveRecord::Base.connection.add_column :list_answers, :code, :string
    Answer.reset_column_information
    ListAnswer.reset_column_information
    
    # copy the values in the code_ref column to the code column because the 
    # addtional answers added later would have the values in the code_ref
    sql_statement = "update list_answers set code = code_ref;"
    ActiveRecord::Base.connection.execute(sql_statement)

    class_def =<<DEF
          class ::LoincAnswerString < ActiveRecord::Base
            set_table_name 'loinc.ANSWER_STRING'
          end
DEF
    eval(class_def)

    class_def =<<DEF
          class ::LoincAnswerList < ActiveRecord::Base
            set_table_name 'loinc.ANSWER_LIST'
          end
DEF
    eval(class_def)

    
    Answer.transaction do
      # copy the exisitng code_ref to the answers table
      AnswerList.all.each do |phr_ll|
        phr_ll.list_answers.each do |la|
          la.answer.answer_string_id = la.code_ref
          la.answer.save!
        end
      end

      # find all lists in the original loinc database
      LoincAnswerList.all.each do |loinc_ll|
        list_id = loinc_ll.ID

        # find the records in the phr join table
        phr_las = ListAnswer.where(answer_list_id: list_id)

        # process the join table records
        phr_las.each do |phr_la|
          phr_answer = phr_la.answer
          answer_text = phr_answer.answer_text
          # find the answer string id in loinc database by answer_text, which
          # is unique too
          loinc_answer = LoincAnswerString.find_by_ANSWER_STRING(answer_text)
          
          if !loinc_answer.ANSWER_STRING_ID.blank?
            answer_code = loinc_answer.ANSWER_STRING_ID
          else
            answer_code = phr_la.code
          end

          # update answers
          phr_answer.answer_string_id = answer_code
          phr_answer.save!
          # update list_answers join table
          phr_la.code = answer_code
          phr_la.save!

        end
      end

    end

  end

  # 6/1/2012
  # update user data after the change of the answer code
  def self.update_answer_code_in_user_obx_table
    Answer.transaction do
      obx_recs = ObxObservation.where('obx5_1_value_if_coded is not null and obx5_1_value_if_coded !=""')
      puts "updating answer code in users obx table... \ntotal records #{obx_recs.length.to_s}... "
      obx_recs.each do |obx_rec|
        loinc_item = LoincItem.find_by_loinc_num(obx_rec.loinc_num)
        answer_list_id = loinc_item.answerlist_id
        answer_text = obx_rec.obx5_value

        answer = Answer.joins(:list_answers).where('answers.answer_text=? and list_answers.answer_list_id=?', answer_text, answer_list_id).first
        if answer
          obx_rec.obx5_1_value_if_coded = answer.code
          obx_rec.save!
        else
          puts "obx record (id=#{obx_rec.id.to_s}) does not find a answer code."
        end
      end
    end
  end

  # 6/19/2012
  # rename the 'answer_string_id' in 'list_answers' table to 'answer_string_code'
  def self.rename_answer_string_code
    # Needed when updating loinc database, now just a memo
    #
    # rename_column :answers, :answer_string_id, :answer_string_code
  end


  # 1/17/2013
  # add two more home-made panels
  # "Blood pressure and other vital signs panel"
  # "Basal body tempeture/ovulation log"
  def self.add_2_panels
    LoincItem.transaction do
      #
      # "Blood pressure and other vital signs panel"
      #
      loinc_item_panel = LoincItem.create!(
        :loinc_num => 'X1400-1',
        :component => 'Blood pressure and other vital signs panel',
        :is_panel => true,
        :has_top_level_panel => true,
        :included_in_phr => true,
        :is_searchable => true,
        :phr_display_name => 'Blood pressure and other vital signs panel'
      )
      loinc_panel_p = LoincPanel.create!(
        :loinc_item_id => loinc_item_panel.id,
        :loinc_num => "X1400-1",
        :sequence_num => 1
      )
      loinc_panel_p.p_id = loinc_panel_p.id
      loinc_panel_p.save!

      # Systolic blood pressure,,8480-6  ,R,Number,,,
      # Diastolic blood pressure,,8462-4  ,R,Number,,,
      # Blood pressure measurement site,,41904-4  ,O,Answer list,,Answer list already in PHR,
      # Blood pressure device Cuff size,,8358-4  ,O,Answer list,,Answer list already in PHR,
      # Body position with respect to gravity,,8361-8  ,O,Answer list,,Answer list already in PHR,
      # Heart rate,,8867-4  ,O,Number,,,
      # Respiratory rate,,9279-1,O,Number,,,
      # Body temperature,,8310-5,O,Number,,,
      # Body temperature measurement site,,8327-9,O,Free text,,,
     
      # add tests
      lp_tests = [
        {:loinc_num => '8480-6', :required => 'R'},
        {:loinc_num => '8462-4', :required => 'R'},
        {:loinc_num => '41904-4', :required => 'O'},
        {:loinc_num => '8358-4', :required => 'O'},
        {:loinc_num => '8361-8', :required => 'O'},
        {:loinc_num => '8867-4', :required => 'O'},
        {:loinc_num => '9279-1', :required => 'O'},
        {:loinc_num => '8310-5', :required => 'O'},
        {:loinc_num => '8327-9', :required => 'O'}
      ]
      sn = 2
      lp_tests.each do | lp_test|
        l_item = LoincItem.find_by_loinc_num(lp_test[:loinc_num])
        LoincPanel.create!(
          :p_id => loinc_panel_p.id,
          :loinc_item_id => l_item.id,
          :loinc_num => lp_test[:loinc_num],
          :sequence_num => sn,
          :observation_required_in_panel => lp_test[:required],
          :type_of_entry => 'Q',
          :observation_required_in_phr => lp_test[:required]
        )
        sn += 1
      end

      #
      # "Basal body tempeture/ovulation log"
      #
      loinc_item_panel = LoincItem.create!(
        :loinc_num => 'X1401-1',
        :component => 'Basal body temperature/ovulation log',
        :is_panel => true,
        :has_top_level_panel => true,
        :included_in_phr => true,
        :is_searchable => true,
        :phr_display_name => 'Basal body temperature/ovulation log'
      )
      loinc_panel_p = LoincPanel.create!(
        :loinc_item_id => loinc_item_panel.id,
        :loinc_num => "X1401-1",
        :sequence_num => 1
      )
      loinc_panel_p.p_id = loinc_panel_p.id
      loinc_panel_p.save!

      # Body temperature,,8310-5,R,Number,,,
      # Body temperature measurement site,,8327-9,O,Free text,,,
      # Menses finding,Do you have your period today?,32400-4,R,Answer list,"Yes, No",answerlist_id = 365,included_in_phr=1

      # add tests
      lp_tests = [
        {:loinc_num => '8310-5', :required => 'R'},
        {:loinc_num => '8327-9', :required => 'O'},
        {:loinc_num => '32400-4', :required => 'O'}
      ]
      sn = 2
      lp_tests.each do | lp_test|
        l_item = LoincItem.find_by_loinc_num(lp_test[:loinc_num])
        LoincPanel.create!(
          :p_id => loinc_panel_p.id,
          :loinc_item_id => l_item.id,
          :loinc_num => lp_test[:loinc_num],
          :sequence_num => sn,
          :observation_required_in_panel => lp_test[:required],
          :type_of_entry => 'Q',
          :observation_required_in_phr => lp_test[:required]
        )
        sn += 1
      end

      #
      # Update 32400-4 to add answer list id and set a flag
      #
      l_item = LoincItem.find_by_loinc_num('32400-4')
      l_item.answerlist_id = 365
      l_item.included_in_phr = true
      l_item.save!
      
    end
  end


  # 7/1/2013
  # Make the panels not in the classification unsearchable
  # and update loinc_names table
  def self.update_loinc_items_and_names
    # loinc_nums in classification
    loinc_in_class = DataClass.select(:item_code)
    loinc_nums= []
    loinc_in_class.map {|a| loinc_nums << a.item_code if a.item_code.match(/-/)}

    # panels loinc_nums in phr
    panels_in_phr = LoincItem.where('is_panel=? and is_searchable=? and included_in_phr=?', true, true, true)
    panels_in_phr.each do |panel_item|
      if !loinc_nums.include?(panel_item.loinc_num)
        panel_item.is_searchable = false
        panel_item.save!
      end
    end


  end
end
