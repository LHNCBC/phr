class DeletedProfile < ActiveRecord::Base
     
  # Delete profile and associated data from phr tables.
  def delete_profile_records_perm
    condition = {}
    condition[:profile_id] = self.id

    DbTableDescription.all.each { |tab|
      condition[:latest] = 'All'
      form_type = tab.data_table
      typed_data_records =@user.typed_data_records(form_type,condition)
      typed_data_records.each { |rec|
        rec.delete
      }
    }
    pu = ProfilesUser.find_by_profile_id(self.id)
    pu.delete
    self.delete
  end

end
