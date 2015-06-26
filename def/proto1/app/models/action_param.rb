class ActionParam < ActiveRecord::Base

  require 'uri'

  # Finds and returns the entry in action_params corresponding to 
  # the given page_url and form field data map.
  #
  # Parameters:
  # * page_url - the URL of the page from which the form_data was submitted.
  #   Only the relative URL is needed, but it can be the full URL.
  # * id_str - If the page_url contains a record ID, this should contain
  #   the ID value.
  # * form_data - a hash of the submitted form field data
  #
  # Returns: The matching ActionParam, or nil if none was found.
  def self.get_action(page_url, id_str, form_data)

    # Get the relative URL.  Do this by removing the part containing the
    # protocol and hostname.  Nope - changed this 12/13/13 BECAUSE the
    # phr_home page was passing an url with a fragment -
    # https://phr_home#rem_list_top - and the fragment (#rem_list_top)
    # was not being removed by the regular expression.  The Ruby URI
    # module handles the path extraction nicely - and the /:nnnnn;edit
    # part of the url for the main phr page remains part of the path.
    #relative_url = page_url.sub(/[^\/]*\/\/[^\/]*/, '')
    relative_url = URI(page_url).path

    if (id_str)
      id_pat = Regexp.new('\/'+id_str+'\b')
      relative_url.sub!(id_pat, '/:id')
    end

    actions =  ActionParam.find_all_by_current_url(relative_url)
    actions.each do |act|
      match = true
      params_h =  act.params_hash
      if !params_h.nil?
        keys = params_h.keys

        if form_data
          keys.each do |key|
            if form_data[key] != params_h[key]
               match = false
               break
            end
          end
        end
      end

      if match
        return act
      end
    end

    return nil
  end


  # Returns the relative URL corresponding to the "next_form" and "next_action"
  # parameters.
  #
  # Parameters:
  # * id_of_record - the ID string for the record to which this URL refers.
  #   This may be nil if it is not applicable.
  def get_next_page_url(id_of_record = nil)
    rtn = redirect_url
    rtn.sub!(/\:id\b/, id_of_record) if id_of_record
    return rtn
  end


  def getParam(pName, mustHave=false)
    if (@fldParams.nil?)
      @fldParams = params_hash
    end
    if (!@fldParams[pName].nil?)
      return @fldParams[pName]
    elsif (mustHave)
      raise pName + ' was not found in the parameters loaded from the ' +
                    'control_type_details field'
    else
      return nil
    end
  end

  # Provides a hash map of the parameters contents.  Values can
  # be a string, an array of strings (the ones enclosed in parentheses), or a
  # hash map of string key/value pairs (the ones enclosed in braces).
  def params_hash
    ActionParam.parse_hash_value(conditions)
  end
  
  # get the array of keys for elements in the params hashmap
  def get_keys
     params_hash.keys
  end

end
