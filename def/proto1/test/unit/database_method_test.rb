require 'test_helper'

class DatabaseMethodTest < ActiveSupport::TestCase
  def test_get_uncopiable_tables
    DatabaseMethod.copy_development_tables_to_test('db_table_descriptions')
    uncopiable_tables = DatabaseMethod.get_uncopiable_tables
    puts "ut = #{uncopiable_tables.to_json}"
    %w(users profiles_users profiles phrs phr_drugs obr_orders).each do |t|
      assert(uncopiable_tables.member?(t), "#{t} should not be copiable")
    end
  end


  def test_get_copiable_tables
    DatabaseMethod.copy_development_tables_to_test(['db_table_descriptions'])
    copiable_tables = DatabaseMethod.get_copiable_tables
    %w(users phr_drugs).each do |t|
      assert(!copiable_tables.member?(t), "#{t} should not be copiable")
    end

    %w(forms field_descriptions).each do |t|
      assert(copiable_tables.member?(t), "#{t} should be copiable")
    end
  end
end
