# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Proto1::Application.initialize!

# Don't define constants here.  Define them in them in constants.rb
# These don't count.
# A directory for all PHR related JavaScript files
JS_DIR = File.join(Rails.root, "public/javascripts")
JS_ASSET = File.join(Rails.root, "app/assets/javascripts")
