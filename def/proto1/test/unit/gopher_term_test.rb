require 'test_helper'

class GopherTermTest < ActiveSupport::TestCase
  fixtures :gopher_terms, :icd9_codes, :gopher_term_synonyms, :word_synonyms

  # Tests the term_icd9_code and term_icd9_text methods.
  def test_term_icd9
    term = gopher_terms(:one)
    assert_equal('098.82', term.term_icd9_code)
    assert_equal('Gonococcal meningitis', term.term_icd9_text)
    term = gopher_terms(:three)
    assert_nil(term.term_icd9_code)
    assert_nil(term.term_icd9_text)
  end


  # Tests the word_synonyms method
  def test_word_synonyms
    assert_equal('FUNGUS;FUNGAL;FUNGII;MOLD;MILDEW;YEAST',
       gopher_terms(:three).word_synonyms)
  end

  # Tests the synonyms method
  def test_synonyms
    term = gopher_terms(:one)
    assert_equal(['Meningococcus', 'N meningitidis'], term.synonyms)
    term = gopher_terms(:two)
    assert_equal(['smoker'], term.synonyms)
    term = gopher_terms(:three)
    assert_equal([], term.synonyms)
  end


  # Test find_storage_by_contents (has_searchable_lists.rb).
  def test_find_storage_by_contents
    GopherTerm.rebuild_index
    results = GopherTerm.find_storage_by_contents(nil,
      'me*', nil, [:consumer_name], :id, [:id], [:consumer_name, :id], false)
    assert_equal(2, results[0], 'total hits should be 2')
    codes = Set.new(['100001', '100003'])
    assert_equal(codes, Set.new(results[1]))
    # Check the returned data hash (results[2])
    returned = codes
    assert_equal(1, results[2].size)
    assert_equal(returned, Set.new(results[2][:id]))
    # Check the record data
    record_data = Set.new([['Neisseria Meningitidis', '100003'],
                           ['Meningitis Fungal', '100001']])
    assert_equal(record_data, Set.new(results[3]))

    # Now turn on highlighted and test.
    results = GopherTerm.find_storage_by_contents(nil,
      'me*', nil, [:consumer_name], :id, [:id], [:consumer_name, :id], true)
    record_data = Set.new([['Neisseria <span>Meningitidis</span>', '100003'],
                           ['<span>Meningitis</span> Fungal', '100001']])
    assert_equal(record_data, Set.new(results[3]))
  end


  # Test find_fuzzy_items (has_searchable_lists.rb)
  def test_find_fuzzy_items
    GopherTerm.rebuild_index
    results = GopherTerm.find_fuzzy_items(nil,
      'Meningitiza', nil, [:consumer_name], :id, [:consumer_name])
    assert_equal(2, results.length)
    returned_codes, returned_displayed_text = results
    assert_equal(2, returned_codes.length)
    assert_equal(2, returned_displayed_text.length)
    expected_codes = Set.new(['100001', '100003'])
    assert_equal(expected_codes, Set.new(returned_codes))
    expected_displayed_text = Set.new([['Neisseria Meningitidis'],
                                      ['Meningitis Fungal']])
    assert_equal(expected_displayed_text, Set.new(returned_displayed_text))

    # Test a query that won't find anything unless the code that removes
    # terms runs.
    results = GopherTerm.find_fuzzy_items(nil,
      'Meningitiza xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', nil,
      [:consumer_name], :id, [:consumer_name])
    # The results should be the same as before
    assert_equal(2, results.length)
    returned_codes, returned_displayed_text = results
    assert_equal(2, returned_codes.length)
    assert_equal(2, returned_displayed_text.length)
    assert_equal(expected_codes, Set.new(returned_codes))
    assert_equal(expected_displayed_text, Set.new(returned_displayed_text))
  end


  # Test add_default_wildcards (from has_searchable_lists.rb)
  def test_add_default_wildcards
    # Note:  acid is a stop word for drugs, so we use that class instead
    # of GopherTerm.  (Actually, the stop words are currently shared,
    # but I hope to change that someday.)
    assert_equal('+a? +b* +c/ +d* acid* +e*',
      DrugNameRoute.add_default_wildcards('a? b* c/d acid e'))
  end
end
