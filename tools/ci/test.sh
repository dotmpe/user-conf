#!/bin/sh

set -e

hostnameid=

uc_lib=script/user-conf
. "$uc_lib"/lib.sh

mkdir -vp build
test ! -e ./build/test-results.tap || rm ./build/test-results.tap

exec 5> ./build/test-results.tap
#uc__test "$@" 1>&5 || result=$?
bats test/*-spec.bats 1>&5 || result=$?
exec 5<&-

test ! -s ./build/test-results.tap || {
  log "Test results:"
  cat ./build/test-results.tap | script/bats-colorize.sh
}

test -n "$result" -o "$result" = "0" &&
  log "Test fail, returned '$result'" ||
  log "Test OK"

exit $result

# Sync: BIN:
# Sync: U-S:
