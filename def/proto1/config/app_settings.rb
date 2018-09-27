original_verbose = $VERBOSE
$VERBOSE = nil  # suppress warning
# TBD - specify for your system
PHR_SUPPORT_EMAIL = 'phrgeneric@mailinator.com'
$VERBOSE = original_verbose
ActiveSupport::Deprecation.silenced = false
