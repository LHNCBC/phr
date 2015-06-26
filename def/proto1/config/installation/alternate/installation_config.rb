# Installation-specific configuration settings for the ALTERNATE installation.

# SITE_OWNER shows up on the print version of the PHR page
# TBD - specify for your alternate system
SITE_OWNER = 'TBD - specify for your alternate system'

# SITE_OWNER_URL goes on the logo in the banner.
SITE_OWNER_URL = 'http://specify.for.your.alternate.system'
URL_HOST_NAME = (HOST_NAME == 'localhost' || HOST_NAME=='localhost2') ?
  'alternate.company.url' : FULL_HOST_NAME

# Text for the banner graphic (for screen readers).
BANNER_ALT_TEXT = 'Banner graphic, with text reading, "TBD - specify
  the alternate organization here; Powered by software from the National Library
  of Medicine"'

# PHR system description used in a shared access invitation
PHR_SYSTEM_NAME = "TBD - Your alternate organization's PHR " +
                  "(Personal Health Record) system"

# the "from" lines used on a shared access invitation
SHARE_INVITE_FROM_LINES = '"from" line 1<br>"from" line 2'