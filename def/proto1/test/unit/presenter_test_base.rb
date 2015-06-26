require 'test_helper'

# A base "class" for some of the tests for presenters.  (This is a module,
# because otherwise the tests get run for the base class, which doesn't work.)
module PresenterTestBase

  def setup
    DatabaseMethod.copy_development_tables_to_test(['field_descriptions',
      'forms', 'text_lists', 'text_list_items',  'db_table_descriptions',
      'db_field_descriptions'])
  end

  # Tests the fields in the presenter
  def test_fields
    presenter_class_name = self.class.name.slice(0..-5)
    presenter_class = presenter_class_name.classify.constantize
    sp = presenter_class.new
    assert_not_nil sp.form
    assert_not_nil sp.form_obj
    # Check the fields used in the basic mode.
    presenter_class.fields_used.each {|name| assert_not_nil sp.fds[name], name}
  end
end
