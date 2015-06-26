# The email address validation in User model is depend on the data in 
# regex_validators table, therefore, we have to make sure that table is always loaded
if Rails.env == "test"
  unless RegexValidator.where(code: "email").first
    DatabaseMethod.copy_development_tables_to_test(%w(regex_validators))
  end
end
email_validator = RegexValidator.where(code: "email").first
EMAIL_REGEX = email_validator.regex_in_ruby
EMAIL_ERROR_MESSAGE = email_validator.error_message

user_name_validator = RegexValidator.where(code: "user_name").first
USER_NAME_REGEX = user_name_validator.regex_in_ruby
USER_NAME_ERROR_MESSAGE = user_name_validator.error_message
