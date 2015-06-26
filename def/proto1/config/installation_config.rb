# Installation-specific configuration settings.

# SITE_OWNER shows up on the print version of the PHR page
SITE_OWNER = 'National Library of Medicine'

# SITE_OWNER_URL goes on the logo in the banner.
SITE_OWNER_URL = 'http://www.nlm.nih.gov'
URL_HOST_NAME = (HOST_NAME == 'phrapp1' || HOST_NAME=='phrapp2') ?
  'phr.nlm.nih.gov' : FULL_HOST_NAME

# Text for the banner graphic (for screen readers).
BANNER_ALT_TEXT = 'Banner graphic, with National Library of Medicine logo and 
  text reading, "Personal Health Record"'

# PHR system description used in a shared access invitation
PHR_SYSTEM_NAME = "the National Library of Medicine's PHR " +
                  "(Personal Health Record) system"

# the "from" lines used on a shared access invitation
SHARE_INVITE_FROM_LINES = 'The NLM PHR Team<br>phr@nlm.nih.gov'
