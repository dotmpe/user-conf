#!/bin/sh

$LOG notice :tools/ci/test "Starting unit tests"
#UC_LIB_PATH=${U_C:?}/script
#uc_lib=script/user-conf
#. "$uc_lib"/lib.sh

mkdir -vp build
test ! -e ./build/test-results.tap || rm ./build/test-results.tap

bats_report=./build/test-results.tap

#$LOG info :tools/ci/test "Test suites:" "$(echo test/[a-z]*-spec.bats)"
#exec 5> "$bats_report"
bats test/[a-z]*-spec.bats >"$bats_report" || test_status=$?
#exec 5<&-

test ! -s "$bats_report" || {
  $LOG info :tools/ci/test "Test results:"
  < "$bats_report" script/bats-colorize.sh
}

test "0" = "${test_status:-0}" &&
  $LOG notice :tools/ci/test "Test OK" ||
  $LOG warn :tools/ci/test "Test fail: E$_"
