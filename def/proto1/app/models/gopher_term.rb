# Models data from the Term table of the Regenstrief Gopher program
class GopherTerm < ActiveRecord::Base
  has_paper_trail
  has_many :gopher_term_synonyms
  belongs_to :icd9_code

  extend HasSearchableLists
  include HasClassification

  DEFAULT_CODE_COLUMN = "key_id"

  @@word_synonyms_hash = nil


  # initialize word synonym hash by parsing the data in word_synonyms table
  #
  # Note: method 'initialize' is not called when an ActiveRecord object is
  # created from a database record
  #
  def init_word_synonyms
    @@word_synonyms_hash = {}
    syn_records = WordSynonym.find(:all)
    syn_records.each do | syn_rec |
      word_set = syn_rec.synonym_set
      words = word_set.split(';')
      words.each do |word|
        @@word_synonyms_hash[word] = word_set
      end
    end
  end


  # Returns the ICD9 code, or nil if there isn't one
  def term_icd9_code
    icd9_code.nil? ? nil: icd9_code.code
  end

  # Returns the ICD9 text, or nil if there isn't one
  def term_icd9_text
    icd9_code.nil? ? nil: icd9_code.description
  end

  # Returns the synonyms for this term as an array.  (We used to concatenate
  # (see version 1.16), but Ferret supports indexing of arrays of strings for
  # the case where it is useful to treat each element as a separate value.
  def synonyms
    gts = gopher_term_synonyms
    sArray = [];
    gts.each { |s| sArray << s.term_synonym }
    sArray.sort!
  end

  # Returns the consumer name for the field, which might be the same as
  # the "primary_name".  (In cases where they are the same, the consumer_name
  # column is actually empty, so we return the value in primarty_name instead.)
  def consumer_name
    rtn = read_attribute('consumer_name')
    rtn = read_attribute('primary_name') if !rtn
    return rtn
  end

  # Define a duplicate of the "primary_name" model-derived method that will
  # be used for sorting the results when searching.  ("primary_name" gets
  # tokenized; this one won't be.
  def primary_name_for_sort
    return self.primary_name
  end

  # Define a duplicate of the "consumer_name" method that will
  # be used for sorting the results when searching.  ("consumer_name" gets
  # tokenized; this one won't be.
  def consumer_name_for_sort
    return self.consumer_name
  end

  set_up_searchable_list(:id,
     [:consumer_name, :primary_name, :word_synonyms, :synonyms,
      :included_in_phr, :term_icd9_code, :key_id, :is_procedure],
     [:consumer_name_for_sort, :document_weight])


  # Override Ferret's to_doc method, to assign a boost value to the document.
  def to_doc
    doc = super
    doc.boost = document_weight
    return doc
  end

  # Get the word synonyms from the word_synonyms table
  def word_synonyms
    init_word_synonyms if !@@word_synonyms_hash
    syn_sets = []
    pri_name = read_attribute('primary_name')
    names = self.class.words_in_term(pri_name)
    names.each do |name|
      word_set = @@word_synonyms_hash[name.upcase]
      syn_sets << word_set unless word_set.nil?
    end
    return syn_sets.join(';')
  end


  # Returns the words in a term as an array
  #
  # Parameters:
  # * term - the term to be broken up into words
  def self.words_in_term(term)
    term.gsub(/[()]/,' ').split(' ')
  end


  # Prints out a list of gopher_terms with word synonyms next to the words
  # in the terms (but one synonym at a time).
  def self.print_terms_with_word_synonyms
    GopherTerm.where(included_in_phr: true).order(:primary_name).each do |gt|
      pri_name = gt.read_attribute('primary_name')
      puts
      puts "Primary name:  #{pri_name},  Consumer name:  #{gt.consumer_name}"
      words = words_in_term(gt.consumer_name)
      words.each_with_index do |word, i|
        word = word.upcase
        synonym_set = @@word_synonyms_hash[word]
        if synonym_set
          first_part = words[0..i].join(' ')
          last_part = words[i+1..-1].join(' ')
          synonym_set.split(';').each do |synonym|
            puts "#{first_part}[#{synonym}] #{last_part}" if word != synonym
          end
        end
      end
    end
  end

  # Prints a list of the gopher_terms consumer names, and below each name
  # are listed the word synonyms that are assocaiated with the term.
  def self.print_terms_and_word_synonyms
    GopherTerm.where(included_in_phr: true).order(:primary_name).each do |gt|
      puts
      puts "Primary name:  #{gt.primary_name},  Consumer name:  #{gt.consumer_name}"
      if gt.word_synonyms.blank?
        puts '  Word synonyms: (none)'
      else
        puts "  Word synonyms:\n    #{gt.word_synonyms}"
      end
    end
  end


  # Prints out a list of unique words used in the PHR from either the
  # consumer name or primary name fields.
  def self.print_words
    word_set = Set.new
    GopherTerm.where(included_in_phr: true).each do |gt|
      terms = [gt.primary_name]
      terms << gt.consumer_name if gt.primary_name != gt.consumer_name
      terms.each do |term|
        words_in_term(term).each {|w| word_set << w}
      end
    end
    puts word_set.to_a.sort.join("\n")
  end


  # Returns data for information links about a problem
  #
  # Parameters:
  # * code - the code for the gopher term, or nil if not known.
  # * name - the text of the gopher term.
  #
  # Returns:
  # An array of length 2 arrays.  Each entry is URL and page title for an
  # Mplus page related to this drug.
  # Returns array size zero if no matches meet query conditions.
  def self.info_link_data(code, name)
    if code
      recs = GopherTermsMplusHt.find_all_by_gopher_key_id(code)
    else
      recs = GopherTermsMplusHt.find_all_by_gopher_primary_name(name)
    end
    recs.collect {|rec| [rec.urlid , rec.mplus_page_title]}
  end


  # Returns data for information links about this problem
  #
  # Returns:
  # An array of length 2 arrays.  Each entry is URL and page title for an
  # Mplus page related to this drug.
  # Returns array size zero if no matches meet query conditions.
  def info_link_data
    if key_id
      recs = GopherTermsMplusHt.find_all_by_gopher_key_id(key_id)
    else
      recs = GopherTermsMplusHt.find_all_by_gopher_primary_name(primary_name)
    end
    recs.collect {|rec| [rec.urlid , rec.mplus_page_title]}
  end


  # for test only 7/12/2010
  # over 80 records have different word synonyms before and after
  # (Tests the difference between old_word_synonyms and the generated ones.)
  def self.test_word_synonyms
    gts = GopherTerm.find(:all)
    i = 0
    gts.each do |gt|
      if gt.word_synonyms_old != gt.word_synonyms && !gt.word_synonyms_old.nil?
        set_old = gt.word_synonyms_old.split(';') - ['']
        set_new = gt.word_synonyms.split(';') - ['']
        set_old2 = []
        set_old.each do |word|
          set_old2 << word.strip
        end
        set_diff = set_old2 - set_new

        if !set_diff.empty?
          puts "Gopher Term ID : " + gt.id.to_s
          puts "Primary Name   : " + gt.primary_name
          puts "Diff: " + set_diff.join(';')
          puts "Old : " + gt.word_synonyms_old
          puts "New : " + gt.word_synonyms
          puts " "
          i += 1
        end
      end
    end
    puts "Total diff : " + i.to_s
  end
end
