#!/bin/sh

set -e

hostnameid=

uc_lib=script/user-conf
. "$uc_lib"/lib.sh

mkdir -vp build
test ! -e ./build/test-results.tap ||
  rm ./build/test-results.tap

log "Hostname: $(hostname)"

exec 3> ./build/test-results.tap
c_test "$@" 1>&3 || result=$?
exec 3<&-

log "Test returned '$result'"

cat build/test-results.tap

exit $result

