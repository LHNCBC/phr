l# Installation-specific configuration settings.

# SITE_OWNER shows up on the print version of the PHR page
SITE_OWNER = 'TBD - Your Organization Name Here'

# SITE_OWNER_URL goes on the logo in the banner.
SITE_OWNER_URL = 'http://TBD - YOUR URL HERE'
URL_HOST_NAME = (HOST_NAME == 'hostname' || HOST_NAME=='hostname2') ?
  'your.host.address.com' : FULL_HOST_NAME

# Text for the banner graphic (for screen readers).
BANNER_ALT_TEXT = 'Banner graphic, with TBD YOUR logo and
  text reading, "Personal Health Record"'

# PHR system description used in a shared access invitation
PHR_SYSTEM_NAME = "TBD Your Organization's PHR " +
                  "(Personal Health Record) system"

# the "from" lines used on a shared access invitation
SHARE_INVITE_FROM_LINES =
  "TBD Your Organization's PHR Team<br>phr@your.org.com"

# Site owner's email address
SITE_OWNER_EMAIL = 'TBD - your@email.address.com'