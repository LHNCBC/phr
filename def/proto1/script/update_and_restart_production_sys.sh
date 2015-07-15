#!/bin/sh
#
# This script is meant to start the system in production mode

#delete generated javascripts
cd /home/phr/def/proto1
rm -f app/assets/javascripts/gnd_*.js

# Clear existing cache
rake tmp:cache:clear

# Clear existing precompiled assets
rake assets:clobber

# Precompile updated assets
rake def:setup_assets RAILS_ENV=production

# Generator reminder rule js assets to be used on nodejs
rake def:generate_reminder_rule_js RAILS_ENV=production

# Bring up the web app to populate the fragment caches
script/startWebserver.sh
rake def:preload_fragment_caches PRELOAD_HOST=127.0.0.1
