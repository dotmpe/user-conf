#!/bin/sh

$LOG notice :tools/ci/test "Starting unit tests"
#UC_LIB_PATH=${U_C:?}/script
#uc_lib=script/user-conf
#. "$uc_lib"/lib.sh

mkdir -vp build
test ! -e ./build/test-results.tap || rm ./build/test-results.tap

bats_report=./build/test-results.tap
#exec 5> "$bats_report"
bats test/[a-z]*-spec.bats >"$bats_report"
#exec 5<&-

test ! -s "$bats_report" || {
  $LOG info "" "Test results:"
  cat "$bats_report" | script/bats-colorize.sh
}

#test -n "$result" -o "$result" = "0" &&
#  log "Test fail, returned '$result'" ||
#  log "Test OK"
