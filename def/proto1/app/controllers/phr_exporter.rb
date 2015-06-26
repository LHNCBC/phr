# This contains a method for the two controllers that export PHR records.
module PhrExporter
  # Handles the response for a request to export the given profile.
  #
  # Parameters:
  # * profile - the profile to be exported
  # * file_format - the format parameter ('1' for CSV, '2' for Excel)
  # * file_name - the name for the file.  Optional.  If not supplied, the
  #   default file name assigned by the Profile model class will be used.
  #   currently that is the pseudonym for the profile
  #
  def handle_export_request(profile, file_format, file_name=nil)
    export_data, file_name = profile.export('phr', file_format, 
                                            @user.id, file_name)
    content_type = file_format=='2' ? 'application/vnd.ms-excel' : 'text/csv'
    send_data export_data, :disposition => 'attachment',
      :filename => file_name, :type=>content_type
    # I'm not sure why passing :type above does not work; but setting
    # the content-type header below does.
    headers['Content-Type'] = content_type
  end
end
