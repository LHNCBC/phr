# Installation-specific configuration settings for the DEFAULT installation.

# SITE_OWNER shows up on the print version of the PHR page
SITE_OWNER = "TBD - Your organization's name"

# SITE_OWNER_URL goes on the logo in the banner.
SITE_OWNER_URL = 'http://your.organization.url'
URL_HOST_NAME = (HOST_NAME == 'localhost' || HOST_NAME=='host2') ?
  'your.organization.hostname' : FULL_HOST_NAME

# Text for the banner graphic (for screen readers).
BANNER_ALT_TEXT = 'Banner graphic for your organization, and
  text reading "Personal Health Record"'

# PHR system description used in a shared access invitation
PHR_SYSTEM_NAME = "the TBD - your organization's PHR " +
                  "(Personal Health Record) system"

# the "from" lines used on a shared access invitation
SHARE_INVITE_FROM_LINES = 'TBD - your organization'

# Site owner's email address
SITE_OWNER_EMAIL = 'TBD - your@email.address.com'