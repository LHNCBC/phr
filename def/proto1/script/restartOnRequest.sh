#!/bin/sh
# Restarts the Rails server if requested via the existence of a RESTART file.
# It is used by the data controller.
cd `dirname $0`
if test -e /tmp/PHR_RESTART; then
  rm /tmp/PHR_RESTART
  cd ../../apache
  ./apache.sh restart
fi
