#!/bin/sh

echo Starting CI test >&2

#UC_LIB_PATH=${U_C:?}/script
#uc_lib=script/user-conf
#. "$uc_lib"/lib.sh

mkdir -vp build
test ! -e ./build/test-results.tap || rm ./build/test-results.tap

exec 5> ./build/test-results.tap
for bats_case in test/[a-z]*-spec.bats
do
  $LOG notice "" "Testing..." "$bats_case"
  bats "$bats_case" 1>&5 || result=$?
done
exec 5<&-

test ! -s ./build/test-results.tap || {
  $LOG info "" "Test results:"
  cat ./build/test-results.tap | script/bats-colorize.sh
}

#test -n "$result" -o "$result" = "0" &&
#  log "Test fail, returned '$result'" ||
#  log "Test OK"
