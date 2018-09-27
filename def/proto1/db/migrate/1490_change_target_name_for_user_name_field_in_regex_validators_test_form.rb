class ChangeTargetNameForUserNameFieldInRegexValidatorsTestForm < ActiveRecord::Migration[5.1]

  def up
    if MIGRATE_FFAR_TABLES
      FieldDescription.transaction do
        change_target_field('REGEX_VALIDATORS_TEST', 'user_name', 'test_user_name')
      end
    end
  end

  def down
    if MIGRATE_FFAR_TABLES
      FieldDescription.transaction do
        change_target_field('REGEX_VALIDATORS_TEST', 'test_user_name', 'user_name')
      end
    end
  end

  private

  def change_target_field(form_name, old_value, new_value)
    test_form = Form.where(:form_name => form_name).take
    user_name_field = test_form.fields.find { |field| field.target_field == old_value }
    user_name_field&.update_attributes!(:target_field => new_value)
  end

end
