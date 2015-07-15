class AddVmLink < ActiveRecord::Migration
  def self.up

    # Adds a link to the PHR Demo Login form.  The link points to the page
    # that provides access to the Virtual Machine (VM) download.

    if MIGRATE_FFAR_TABLES 
      Form.transaction do
        fm = Form.where(:form_name => 'demo_login').take
        fld = FieldDescription.where(:form_id => fm.id,
                                     :target_field => 'instructions2').take
        fld.default_value = fld.default_value + '<br><br>The PHR system is ' +
                            'also available for ' +
                            '<a href="https://phr-demo.nlm.nih.gov/vm/startup.html"> '+
                            'download</a>, implemented as a virtual ' +
                            'machine (VM).'
        fld.save!
      end # transaction
    end # if MIGRATE_FFAR_TABLES
  end # up

  def self.down
   if MIGRATE_FFAR_TABLES
      Form.transaction do
        fm = Form.where(:form_name => 'demo_login').take
        fld = FieldDescription.where(:form_id => fm.id,
                                     :target_field => 'instructions2').take
        fld.default_value = fld.default_value.gsub('<br><br>The PHR system is ' +
                            'also available for ' +
                            '<a href="https://phr-demo.nlm.nih.gov/vm/startup.html"> '+
                            'download</a>, implemented as a virtual ' +
                            'machine (VM).', '')
        fld.save!
      end # transaction
    end # if MIGRATE_FFAR_TABLES
  end # down
end