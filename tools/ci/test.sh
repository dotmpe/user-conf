#!/bin/sh

set -e

hostnameid=

uc_lib=script/user-conf
. "$uc_lib"/lib.sh

mkdir -vp build
test ! -e ./build/test-results.tap || rm ./build/test-results.tap

exec 3> ./build/test-results.tap
#uc__test "$@" 1>&3 || result=$?
bats test/*-spec.bats 1>&3 || result=$?
exec 3<&-

test ! -s ./build/test-results.tap || {
  log "Test results:"
  cat ./build/test-results.tap | script/bats-colorize.sh
}

test -n "$result" -o "$result" = "0" &&
  log "Test fail, returned '$result'" ||
  log "Test OK"

exit $result
