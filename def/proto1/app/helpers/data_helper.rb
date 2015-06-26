module DataHelper
  # Creates a link for downloading a table
  #
  # Parameters:
  # * text - the text that should be linked
  # * table - the table to be downloaded
  # * parameters - A CGI parameter string for conditioning the SQL retrieval
  #   of records from table.  If this is nil, the full table wil be returned.
  def download_link(text, table, parameters=nil)
    return "<a href='/data/export/#{table}.csv?#{parameters}'>#{text}</a>".html_safe
  end

  # Creates a link for downloading a table for editing a form's text.
  #
  # Parameters:
  # * form - the form_name of the forms record for the form.
  # * form_title - a user understandable name for the form
  def form_text_link(form, form_title)
    return "<a href='/data/export_form_text/#{form}.csv'>#{form_title}</a>".html_safe
  end
end
