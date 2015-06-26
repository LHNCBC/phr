#
# This function should be called to recreate tables for a form, whenever its
# field denifinition has changed
#
module RecreateFormTables
  def dropTables(form_name)
    fd = FormData.new(form_name)
    fd.dropTables      
  end
  
  def createTables(form_name)
    puts "\n\nCreating PHR Tables...... Be patient.....\n\n"
    fd = FormData.new(form_name)
    fd.createTables
  end
  
  
  def recreateTables(form_name)
    puts "\n\nRecreating PHR Tables...... Be patient.....\n\n"
    fd = FormData.new(form_name)
    fd.dropTables      
    fd.createTables
  end
    
end
