# Defines the user table model classes.
#
# The following used to be called in environment.rb, but for some reason when
# running rake in production mode we then had to require the environment file
# first, like:
#   rake RAILSENV=production --require 'config/environment' db:test:clone
# in order to run this command after the model classes were defined.
# Putting it here, after the class is defined, removes that problem.
require_dependency 'active_record_extensions'
require_dependency 'active_record_cache_mgr'


DbTableDescription.define_user_data_models

# Load the PHR Support form name.  (I did not want to create a separate
# initializer for this small amount of code.  Putting it into environment.rb
# did not work, because the constant below is used when LoginController is read.
support_form = Form.where(form_name: 'contact_support').first
# Note:  support_form will likely be nil in test mode
SUPPORT_PAGE_NAME = support_form ? support_form.form_title : 'Support'