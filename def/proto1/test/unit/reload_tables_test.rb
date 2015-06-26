require 'test_helper'
require File.join(Rails.root, 'db/migrate/modify_tables.rb')

class ModifyTablesTest < ActiveSupport::TestCase
  include ModifyTables

  def test_make_substitutions
    puts "\nreload_tables_test.rb:  Warning: test_make_substitutions is outdated and needs revision"
    if (false) #skip
    get_phrases
    result = make_substitutions('string Hydrochloride string')
    assert_equal('string HCl string', result)
    result = make_substitutions('stringHydrochloride string')
    assert_equal('stringHydrochloride string', result)
    result = make_substitutions('string Hydrochloridestring')
    assert_equal('string Hydrochloridestring', result)
    result = make_substitutions('string ALLERGENIC EXTRACT string')
    assert_nil(result)
    result = make_substitutions('stringALLERGENIC EXTRACT string')
    assert_equal('stringALLERGENIC EXTRACT string', result)
    result = make_substitutions('string ALLERGENIC EXTRACTstring')
    assert_equal('string ALLERGENIC EXTRACTstring', result)
    result = make_substitutions('string ALLERGENICEXTRACT string')
    assert_equal('string ALLERGENICEXTRACT string', result)
    end
  end

end
