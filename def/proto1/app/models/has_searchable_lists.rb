require 'acts_as_ferret'
module ActsAsFerret
  module InstanceMethods
    # A patch for acts_as_ferret to prevent lock being generated when trying
    # to delete a record from a table whose ferret index was disabled
    def ferret_destroy_with_patch
      ferret_enabled? ? ferret_destroy_without_patch : true
    end
    alias_method_chain :ferret_destroy, :patch
  end
end


# This file contains code for the models that provide an option for
# searching or retrieving lists.  It is intended to be pulled in to a model
# via the extend command.  After the extend command, a model should call
# set_up_searchable_list.
module HasSearchableLists
  include Ferret
  include Ferret::Search

  # Limits the number of items returned by find_fuzzy_items.
  MAX_FUZZY_ITEMS = 5

  # Sets up the list for searching.  Modules should call this from the class
  # definition.
  #
  # Parameters:
  # * code_field - the field in the list table that is the code for the
  #   corresponding list item.  If this is nil, it will be assumed that
  #   the list items do not have codes.  If it is not nil, the code field
  #   will be indexed along with the fields in "fields".  This should be a
  #   symbol.
  # * fields_indexed - an array of the the names of the fields (as symbols) to
  #   be indexed
  # * sort_fields - a list of the names of the fields (as symbols) that should
  #   be available for sorting the results (e.g. via the "order" parameter
  #   in the control_type_detail of a form field.)  These are not for searchable
  #   fields, so if you want to search and sort the same field, you need to
  #   make another method in your model class that returns the field value,
  #   e.g. "def field_for_sort\n  return field\n end".
  def set_up_searchable_list(code_field, fields_indexed, sort_fields=nil)
    @code_field = code_field
    @non_code_fields = fields_indexed
    @index_fields = fields_indexed.clone
    # Add the code field to the index_fields but only if it is not :id, which
    # is already added (automatically, I think).
    if (code_field && code_field != :id)
      @index_fields.push(code_field)
    end
    
    self.make_ferret_index_with_data(@index_fields, sort_fields)
  end

  
  # Returns the symbol for the list ID column.  Models that support multiple
  # lists should override this to provide the value.
  def get_list_id_column
    raise 'The model should have overridden get_list_id_column'
  end


  # Define our own version of Ferret's HyphenFilter.  We want the hypenated
  # term to be in the index too.  (HyphenFilter takes "one-two" and stores
  # "one", "two", and "onetwo", but we also want "one-two".
  # Note that we have our own analyzer class (see DefAnalyzer below) that
  # treats - as a word character.
  class HyphenFilter2
    # The current token being processed.
    @cur_token = nil

    # An array of the words to be returned as tokens before moving on to the
    # next token given to this filter.
    @words = nil

    # An index into @words for the next word to be returned
    @words_index = 0

    # The underlying token stream
    @token_stream = nil

    # The ending index of the last token returned (within the string)
    @end_token_index = nil

    # Creates a new one
    #
    # Parameters:
    # * token_stream - the underlying token stream that this filter wraps
    def initialize(token_stream)
      @token_stream = token_stream
    end

    # Returns the next token
    def next
      next_token = nil
      # Must be fast for non-hyphen case (which is more common)
      if !@cur_token || !@words || @words_index>=@words.length
        next_token = @token_stream.next
        if next_token
          token_text = next_token.text
          if (token_text.index('-'))
            @cur_token = next_token
            # The first time through we let through the hyphenated form,
            # e.g. 'one-two' as the token text.
            @words = [token_text.gsub(/-/, '')].concat(token_text.split('-'))
            # e.g. @words = ['onetwo', 'one', two']
            @words_index = 0 # for the next one
            @end_token_index = next_token.end
          end
        end
      else
        # Update @cur_token
        next_token = @cur_token
        next_token_text = @words[@words_index]
        next_token.text = next_token_text
        # Set the position increment.  This should be 1 when moving to
        # a new token, 0 for the first two words in @words (which start at
        # the beginning of the hypenated term) and 1 for the rest.
        next_token.pos_inc = @words_index > 1 ? 1 : 0
        if @words_index > 0
          # Then we need to update the start and ending index
          next_token.start = next_token.end + 1 if @words_index > 1
          next_token.end = next_token.start + next_token_text.length
        end
        @words_index += 1
      end
      return next_token
    end

    # Sets the text being parsed.  I think this is only used when you
    # re-use the instance to parse a new query, which we don't, except
    # when experimenting from the console.
    def text=(new_text)
      @token_stream.text = new_text
    end
  end


  
  # Define our own Analyzer class.  We would like to use LetterAnalyzer,
  # but need stop words.  Also, we want to be able to search on numbers.
  class DefAnalyzer
    def token_stream(field, str)
      ts = Ferret::Analysis::RegExpTokenizer.new(str, /[[:alnum:]\.\-]+/)
      ts = Ferret::Analysis::LowerCaseFilter.new(ts)
      # I am commenting out the use of the stop words, because right now
      # if the user types something like "zinc glucon" nothing is found even
      # though "zinc gluconate" is in the list (because gluconate is a stop
      # word.  Clem thinks the statistics will likely obviate the need for
      # having these salts as stop words.  (2010/12/10)
      # ts = Ferret::Analysis::StopFilter.new(ts, StopWords.get_all_stop_words)
      ts = HyphenFilter2.new(ts)
    end
  end
  
  
  # This is a wrapper around "acts_as_ferret" that sets up a new method
  # for searching that uses a copy of the data stored with the index.  This
  # provides a performance increase, and allows highlighting of search terms.
  #
  # Parameters:
  # * fields - an array of the the names of the fields (as symbols) to
  #   be indexed
  # * sort_fields - a list of the names of the fields (as symbols) that should
  #   be available for sorting the results (e.g. via the "order" parameter
  #   in the control_type_detail of a form field.)
  # * ferret_options - options to pass to the ferret search engine
  def make_ferret_index_with_data(fields, sort_fields=nil, ferret_options={})
    fieldOptions = {}
    @index_fields.each do |f|
      fieldOptions[f] = {:store => :yes}
    end
    
    if (sort_fields)
      sort_fields.each do |f|
         # See p.19-20 of David Balmain's Ferret book
        fieldOptions[f] = {:store => :no, :index => :untokenized,
                           :term_vector=>:no}
      end
    end
    
    if (ferret_options[:analyzer].nil?)
      ferret_options[:analyzer] =
        DefAnalyzer.new
        #Ferret::Analysis::StandardAnalyzer.new(StopWords.get_all_stop_words)
    end

    acts_as_ferret({:fields=>fieldOptions, :ferret=>ferret_options})

    # Turn off automatic indexing, which does not work well with the set
    # controller for some reason.
    disable_ferret

    # A method for searching the ferret index.
    #
    # Parameters:
    # * list_name - the name of the list to search.  For single-list tables,
    #   this doesn't apply, and can be nil.
    # * query - the search query entered by the user
    # * conditions - some extra FQL (ferret query language) to be ANDed with
    #   the user's query.  This may be nil.
    # * fields_searched - the fields to be searched (as symbols)
    # * code_field - the table's column that contains the codes for the records
    # * fields_returned - an array of names of fields (as symbols) that should
    #   be returned as a hash when the data is sent back to the browser.
    #   (We don't actually use this anywhere, and one day, we might remove it,
    #   if it becomes clear that we never will use it.)
    # * fields_displayed - the fields to be displayed.  
    # * highlighting - if passed true, the values for the fields_displayed
    #                  fields will have highlighting on the matched terms.
    #                  if passed false, no highlighting will be applied.
    #                  (added 6/13/07)
    # * options - an optional hash of options to the ferret search engine
    #
    # Returns:
    # The total count available, an array of codes for the returned records,
    # a hash map (described below), and an array of record data (each of which
    # is an array whose elements are 
    # the values of the fields specified in the field_displayed parameter).
    # The hash map is from fields_returned elements to corresponding lists of
    # field values.  This structure was chosen to
    # minimize the size of the JSON version of the return data, because
    # the returned fields data gets included in the output sent back to
    # the web browser.  If highlighting is turned on, :display values will have
    # <span> tags around the terms that matched the query.
    #
    # Originally based on the method by Gregg Pollack and Jason Seifer at:
    # http://www.railsenvy.com/2007/2/19/acts-as-ferret-tutorial
    def self.find_storage_by_contents(list_name, query, conditions,
                                      fields_searched, code_field,
                                      fields_returned, fields_displayed, 
                                      highlighting, options = {})

      index = aaf_index.ferret_index # Get the index that acts_as_ferret created

      returned_field_data = {} # field name to list of values
      fields_returned.each { |f| returned_field_data[f] = [] }
      displayed_data = []
      item_codes = []

      # Remove parentheses (which appear in some of the results, e.g.
      # "Aspirin (Oral-pill)", which might get sent back as a search string).
      query.gsub!(/[\(\)]/, '')

      query = add_default_wildcards(query)
      query = add_query_conditions(query, conditions)
      # Parse the query ourselves so we can specify which fields are searched
      query = parse_query(query, fields_searched)
      
      # If the list_name is not nil, require that hits be from the correct list
      query = add_list_name(query, list_name) if list_name

      # search_each is the core search function from Ferret, which
      # Acts_as_ferret hides
      total_hits = index.search_each(query, options) do |doc_id, score|
        doc = index[doc_id]
        item_codes << doc[code_field]
        
        # Store each field in a hash which we can reference in our views
        fields_returned.each do |f|
          # Ferret does not handle uncocde correctly when indexing.
          # So here and below force_encoding method is called on the content
          # string to convert it to unicode.
          returned_field_data[f] << doc[f].force_encoding('UTF-8')
        end
        
        displayed_record_data = []
        displayed_data << displayed_record_data
        fields_displayed.each do |f|
          if (highlighting)
            # There might not be something to highlight for this field.
            highlight_result = index.highlight(query, doc_id,
                          :field => f, 
                          :pre_tag => '<span>', 
                          :post_tag => '</span>',
                          :num_excerpts => 1)
            if highlight_result
              displayed_record_data << highlight_result[0].force_encoding('UTF-8')
            else
              displayed_record_data << doc[f].force_encoding('UTF-8')
            end
          else
            displayed_record_data << doc[f].force_encoding('UTF-8')
          end
        end
      end
      return [total_hits, item_codes, returned_field_data, displayed_data]
    end # find_storage_by_contents

  end # make_ferret_index_with_data


  # Adds default wildcards to the user's query, and returns the modified
  # query.
  #
  # Parameters:
  # * query - the query to be modified
  def add_default_wildcards(query)
    # First, add a space after a /, because wildcarded terms apparently don't
    # go through Ferret's query analyzer, so we need to break up things
    # like "one/two" which would normally be parsed as two words.
    # Then, add wildcards to the ends of words, being careful not to add
    # a wildcard to a term that already has one at the end.
    query.gsub!(/\//, '/ ')

    # Also, we are careful about stop words, which are not in the
    # index.  However, a stop word might be the beginning of another word.
    # So, we wildcard the stop words (which means they won't be filtered
    # out by the stop word filter) but we don't require their presence.
    # To not require their presence, we rely on the parse_query method
    # using an or_default of true, so that no terms are required by default,
    # and then we require the non-stop words by putting a + in front of them.
    # This solution works for the following two cases:
    # * PHRENILIN WITH CAFFEINE AND CODEINE (Oral-pill)
    # * ANDROLONE-D (Injectable)
    # (Note that both contain words starting with "AND". If you enter one of
    # these two drugs, and then delete the last character, the system still
    # finds them.)
    query_parts = []
    query.split(/\s+/).each do |part|
      first_char = part[0..0]
      last_char = part[-1..-1]
      if first_char!='+' && first_char!='-'
        part = '+' + part if !StopWords.is_stop_word(part)
        part = part + '*' if last_char=~/\w/
      end
      query_parts << part
    end
    query = query_parts.join(' ')
 #   query.gsub!(/([[:alnum:]\-\.]+)(\s|\z)/) { |match|
 #     #is_zero_hit_wildcarded_stop_word($1) ? match : $1 + '*' + $2
 #     wildcarded_match = $1 + '*' + $2
 #     StopWords.is_stop_word($1) ? wildcarded_match : '+' + wildcarded_match
 #   }
    return query
  end


  # Parses a query using DefAnalyzer, and returns the Ferret parsed
  # query structure.
  #
  # Parameters:
  # * query_string - the query to be parsed
  # * fields_searched - the fields to be searched.
  def parse_query(query_string, fields_searched)
    # Note:  or_default needs to be true; see add_default_wildcards,
    # which takes care of ANDing terms by inserting +'s.  We do this
    # to get around the problem of having stop words but wanting wildcards
    # on everything.
    QueryParser.new(:default_field=>fields_searched,
                    :analyzer=>DefAnalyzer.new,
                    :or_default=>true).parse(query_string)
  end


  # A method for finding items in the table that are close to an value a
  # user entered in a field.  It is like spell-check, but instead of a
  # spell check engine it uses a fuzzy search that considers edits on the
  # field value to find similar items in the index.
  #
  # Parameters:
  # * list_name - the name of the list to search.  For single-list tables,
  #   this doesn't apply, and can be nil.
  # * field_val - the value in the field.  This is not intended to be a
  #   general FQL query, but just some text the user typed as a value.
  # * conditions - some extra FQL (ferret query language) to be ANDed with
  #   the user's query.  This may be nil.
  # * fields_searched - the fields to be searched (as symbols)
  # * code_field - the table's column that contains the codes for the records
  # * fields_displayed - the fields to be displayed.
  #
  # Returns:
  # Data for at most MAX_FUZZY_ITEMS items.  The return structure is an array of
  # codes for the returned records, followed by an array of record data (each of
  # which is an array whose elements are the values of the fields specified in
  # the field_displayed parameter).
  def find_fuzzy_items(list_name, field_val, conditions,
                            fields_searched, code_field, fields_displayed)
    index = aaf_index.ferret_index # Get the index that acts_as_ferret created

    displayed_data = []
    item_codes = []

    # Remove parentheses and - and / characters
    field_val.gsub!(/[\(\)-\/]/, ' ')
    field_val.strip!

    # Require all terms
    query_parts = []
    field_val.split(/\s+/).each do |part|
      first_char = part[0..0]
      if first_char!='+' && first_char!='-'
        part = '+' + part
      end
      query_parts << part
    end
    field_val = query_parts.join(' ')

    # Start the similarity at 0.9, and work until we have at lease a minimum
    # number of results.  If the similarity reaches the minimum, then we
    # will start removing words from the query (but keeping the fuzziness).
    similarity = 0.9
    min_similarity = 0.6
    results = []
    codes_of_results = Set.new
    fuzzy_val = nil
    words = nil
    stopping = false
    while (results.length < MAX_FUZZY_ITEMS && !stopping)
      if similarity > min_similarity
        fuzzy_val = field_val.gsub(/(\s+|\Z)/, '~'+similarity.to_s+'\1')
        similarity -= 0.1
      else
        # Try removing words
        words = fuzzy_val.split if !words
        if words.length > 1
          words.pop
          fuzzy_val = words.join(' ')
        else
          stopping = true # there are no more words to remove
        end
      end

      if !stopping
        query = add_query_conditions(fuzzy_val, conditions)
        # Parse the query ourselves so we can specify which fields are searched
        query = parse_query(query, fields_searched)
        # If the list_name is not nil, require that hits be from the correct list
        query = add_list_name(query, list_name) if list_name
        # Save the results, but keep the list unique by checking the code
        index.search(query, {:limit=>MAX_FUZZY_ITEMS}).hits.each do |hit|
          d = index[hit.doc]
          code = d[code_field]
          if !codes_of_results.member?(code)
            results << index[hit.doc]
            codes_of_results << code
            if results.length >= MAX_FUZZY_ITEMS
              stopping = true
              break
            end
          end
        end
      end
    end

    results.each do |doc|
      item_codes << doc[code_field].force_encoding('UTF-8')
      displayed_record_data = []
      displayed_data << displayed_record_data
      fields_displayed.each do |f|
        displayed_record_data << doc[f].force_encoding('UTF-8')
      end
    end

    return item_codes, displayed_data
  end # find_fuzzy_items


  # A test method for searching the index, for use in the console.
  # (Use it via the model class which includes this module, e.g.
  # DrugNameRoute.console_search('one two')).
  # This is useful for seeing search results for a query not preprocessed by
  # the controller (which calls add_default_wildcards).  This displays
  # the result count and the top five results.
  #
  # Parameters:
  # * query_string - the query string to use in searching the index
  def console_search(query_string)
    # Get the index.  Note that in the console, you can do:
    # include Ferret
    # include Ferret::Index
    # index = Index.new(:path=>'index/production/drug_name_route')
    # to get the drug table index.  Here we are in the model class, so we
    # don't need to do that.
    index = aaf_index.ferret_index
    res = index.search(query_string)
    puts "Total hits = #{res.total_hits}"
    puts "Top seven results (with data from the index):"
    i = 1
    res.hits.each do |hit|
      puts index[hit.doc].load.inspect
      i += 1
      break if i>7
    end
    return nil
  end


  # A test method for showing how a query is parsed, for use in the console.
  # This prints out the parsed query.
  # (Use it via the model class which includes this module, e.g.
  # DrugNameRoute.console_parse('one two')).
  #
  # Parameters:
  # * query_string - the query string to use in searching the index
  # * fields - (optional) an array of fields to be searched.  If this is not
  #   specified or is nil, all fields in the index will be searched.  (This is useful
  #   for seeing what the fields are, but usually makes the query hard to read.)
  #   Note that the full list of fields is generally more than what would
  #   be used in a real query.  (It contains the record ID, for instance.)
  def console_parse(query_string, fields=nil)
    fields = aaf_index.ferret_index.reader.fields if ! fields
    puts parse_query(query_string, fields)
  end


  # A test method for showing the tokenization of a query, for use in the
  # console.  This prints out information about each token.  The "pos_inc"
  # field has to do with the position of the token relative to prior token.
  # Usually this is "1" to indicate that the token is the next one, but can
  # be 0 (in the case of tokenization of hyphenated words) or more than one
  # if stop words are removed.
  # (Use this via the model class which includes this module, e.g.
  # DrugNameRoute.console_tokenize('one two')).
  #
  # Parameters:
  # * query_string - the query string to be tokenized
  def console_tokenize(query_string)
    ts = DefAnalyzer.new.token_stream(nil, query_string)
    puts 'start | end | pos_inc | text'
    while t = ts.next
      puts "%5d |%4d | %7d | %s " % [t.start, t.end, t.pos_inc, t.text]
    end
  end

  private

  # Adds FQL conditions to an unparsed query and returns the results.
  #
  # Parameters:
  # * query - the original query
  # * conditions - Ferret Query Language conditions to be added
  def add_query_conditions(query, conditions)
    query = '('+query + ') AND ' + conditions if (!conditions.nil?)
    return query
  end

  # Adds a list name to a parsed query, and returns the result.
  #
  # Parameters:
  # * query - the parsed Ferret query object
  # * list_name - a list name to limit the query.
  def add_list_name(query, list_name)
    new_query = BooleanQuery.new
    new_query.add_query(query, :must)
    list_id = get_list_id_from_name(list_name)
    new_query.add_query(TermQuery.new(get_list_id_column, list_id.to_s),
                       :must)
    return new_query
  end
end # HasSearchableLists

