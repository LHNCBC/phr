# Be sure to restart your web server when you modify this file.
require 'set'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '3.2.3' unless defined? RAILS_GEM_VERSION

# The maximum number of items to show in a (search) auto-completion list.
MAX_AUTO_COMPLETION_SIZE = 7

# The maximum number of items to show in a search results list.
MAX_SEARCH_RESULTS = 500

DATE_ECHO_FMT_D='yyyy MMM dd'
DATE_ECHO_FMT_M='yyyy MMM'
DATE_ECHO_FMT_Y='yyyy'
DATE_RET_FMT_D='%Y %b %d'
DATE_RET_FMT_M='%Y %b'
DATE_RET_FMT_Y='%Y'
TOOLTIP_DELAY=50
ACCESS_KEY_CLOSE='C'

# The timeout period for a session, in minutes
SESSION_TIMEOUT = 60

# The name of the form object (specified in the form_for tag).
FORM_OBJ_NAME = 'fe'  # meant "form entry", I think

# Default field display widths
DEF_STRING_FLD_WIDTH = '20%'
DEF_DATE_FLD_WIDTH = '8.2em'
DEF_INT_FLD_WIDTH = '10em'

# The default CSS style (class name) for buttons.
DEFAULT_BUTTON_STYLE = 'rounded'

# Email addresses for notifications of PHR support requests
# TBD - specify for your system
PHR_SUPPORT_EMAIL = 'phrgeneric@mailinator.com'

# A set of IPs which should be blocked from sending feedback/contact
# emails (e.g. IPs of scanners).
# TBD - specify for your system
NO_EMAIL_IPS = Set.new([])

# Email addresses for notifications when the data controller is used
# to update a table.
# TBD - specify for your system
DATA_UPDATE_EMAILS = []

# Data tables that the data controller is permitted to edit.  These should be
# quoted and separated by commas.
DATA_CONTROLLER_TABLES = ['text_list_items', 'gopher_terms',
          'gopher_term_synonyms', 'gopher_to_meshes', 'gopher_terms_mplus_hts',
          'word_synonyms', 'regex_validators']
# When a form field's list consists of data from multiple table fields, this
# string is used to join the table field values together.  It is also used
# to separate the field values again, so be careful if you change it.
# It cannot just be a space.
TABLE_FIELD_JOIN_STR = ' - '

# The delimiter surrounding values in a field of field type "Set - String".
SET_VAL_DELIM = '|'

# The name & type used for experimental or test or whatever accounts
# Not currently used, 8/2012 lm, but things blow up if they're commented out.
EXP_ACCOUNT_NAME = 'Temporary'
EXP_ACCOUNT_TYPE = 'E'
STD_ACCOUNT_NAME = 'Standard'

# Whether (most) calls made by AJAX autocompleters should require a login.
# This should be true, unless the system does not store any user data that
# could be at risk from CSRF attacks.
REQUIRE_LOGIN_FOR_AJAX = true

# Set up a flag to indicate whether this is the public system or not.
FULL_HOST_NAME = `hostname -f`.chomp
HOST_NAME = FULL_HOST_NAME.slice(/\A[^\.]*/) # just the first segment of it
# The staging system is supposed to behave just like the public one, so
# we tell the code to regard the staging system as the public system.
PUBLIC_SYSTEMS = %w{TBD - SPECIFY FOR YOUR SYSTEM}
PUBLIC_SYSTEM = PUBLIC_SYSTEMS.member?(HOST_NAME)

# Also set a flag to indicate whether this is the baseline system (a.k.a. build system).
BUILD_SYSTEMS = %w{TBD -SPECIFY FOR YOUR SYSTEM}
BASELINE_SYSTEM = BUILD_SYSTEM = BUILD_SYSTEMS.member?(HOST_NAME)

# Set up a flag to indicate whether migrations on FFAR tables should
# be run.  (This is false for the cases where we just copy the FFAR tables.)
# We do not always want to run the migrations, because the code can get out
# of sync with the migration code, and because some data tables are updated
# via the application (e.g. rules).  Also this flag to be controlled with an environment variable,
# so that someone running rake db:migrate can choose to override the normal setting.
# Running rake db:migrate MIGRATE_FFAR=false will run the migrations with MIGRATE_FFAR_TABLES set
# to false.
MIGRATE_FFAR_TABLES = ENV['MIGRATE_FFAR'].nil? ? !PUBLIC_SYSTEM : ENV['MIGRATE_FFAR']!='false'
# MIGRATE_FFAR_TABLES has always been a confusing name.  Try something a little clearer.
MIGRATE_COPIABLE_TABLES = MIGRATE_FFAR_TABLES

# Controls whether to cache ActiveRecord object (for tables that are not
# user data).
USE_AR_CACHE = false# not working with rails 3 # ENV['USE_AR_CACHE'].nil? ? PUBLIC_SYSTEM : ENV['USE_AR_CACHE']=='true'

# Setting for demo user accounts, such user accounts are pre-created on
# the demo system, where the database is reset peoriodically (nightly).
# Demo user accounts should not avaliable on production systems.
# Demo user account type
DEMO_ACCOUNT_TYPE = 'D'
# Demo system name (There should be only one demo site per major site.)
DEMO_SYSTEM = HOST_NAME == 'TBD - specify for your system' ||
              HOST_NAME == 'TBD - specify for your system'
DEMO_RETURN_URL = 'TBD - specify for your system'
# Numbers of demo accounts
DEMO_ACCOUNT_TOTAL = 100000
DEMO_ACCOUNT_INCREMENTAL = 3
# Sample data files for dem accounts
DEMO_SAMPLE_DATA_FILES = ["db/demo_profile_1.yml", "db/demo_profile_2.yml",
    "db/demo_profile_3.yml"]

# test panels 2 tables, required by special code for test panels
OBR_TABLE = 'obr_orders'
OBX_TABLE = 'obx_observations'

# Keys for using Recaptcha
RECAPTCHA_PUBLIC_KEY = 'TBD - specify for your system'
RECAPTCHA_PRIVATE_KEY = 'TBD - specify for your system'

# flag for extra debugging/development features
DEV_DEBUG = true

# Controls whether list field values in saved records should be updated to the
# current values corresponding to the saved list item codes.  We used to
# do that, and have decided against it, in part due to performance concerns.
UPDATE_LIST_VALUES = false

# Prefix for generated Javasript files
GENERATED_JS_PREFIX = "gnd"

# Name of the generated JavaScript file to be used on JavaScript server in order
# to generated reminders at server side
REMINDER_RULE_DATA_JS_FILE = "#{GENERATED_JS_PREFIX}_reminder_rule_data.js"
# A manifest file containing list of Javascript libraries required for generating
# health reminders
REMINDER_RULE_SYSTEM_JS_FILE = "manifest_reminder_rule_system.js"

# Sub-directories of UNCOMP_JS_SUBDIR directory which holds form-specific
# JavaScript source files. When making a generated JavaScript file, system will
# append the source file automatically if the source file exists.
FORM_JS_SUBDIR = "form_js"

# List of autocompleter fields where usage tracking should be enabled
LIST_FIELDS_TRACKED = Set.new ['problem', 'name_and_route', 'surgery_type']

# JavaScript Server Configuration file
JS_SERVER_CONF_FILE = "lib/js_server/config.json"

# Directory for holding form specific stylesheets
FORM_CSS_DIR = "form_css"

# Whether HTTPS should be used
REQUIRE_HTTPS = true

# List of host names where the sensitive information in log files won't be filtered. This list is useful when doing
# debugging on development machines. If you want to disable the log filter, please add your hostname in the local file
# config/app_settings.rb.
# TBD - specify for  your system
HOSTS_WITHOUT_LOG_FILTER =[]

BYPASS_CAPTCHA = false

# The interval for updating the health reminders
REMINDER_UPDATE_INTERVAL = 24

# List of detectable mobile browsers
MOBILE_BROWSERS = ["android", "iphone", "ipod", "ipad","opera mini", "blackberry", "palm","hiptop","avantgo","plucker",
                   "xiino","blazer","elaine", "windows ce; ppc;", "windows ce; smartphone;","windows ce; iemobile",
                   "up.browser","up.link","mmp","symbian","smartphone", "midp","wap","vodafone","o2","pocket","kindle",
                   "mobile","pda","psp","treo"]


