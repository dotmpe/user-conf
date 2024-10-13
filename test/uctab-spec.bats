#!/usr/bin/env bats

load helper
init
scriptname=uctab-spec
@test "1. init" {

  . ./script/user-conf/lib.sh
  . ./tool/u-c/init.sh

  STTTAB_UC=$PWD/test/var/configs.tab
  uc_lib_init &&
  uc_req_uname_facts &&
  uc_req_network_facts &&
  test "$-" = "ehuBET" || fail 1

  id="$($uctab.id)"
  test "${Class__instances[$id]}" = "$STTTAB_UC" ||
    fail "'${Class__instances[$id]}' = '$STTTAB_UC'"

  run $uctab.tab-exists
  test_ok_empty

  run $uctab.tab
  #run stattab_tab "*" "$STTTAB_UC"
  test_ok_nonempty

  run $uctab.list
  #run stattab_list "*" "$STTTAB_UC"
  test_ok_lines "Test-1"
}

#@test "2" {
#  uc_conf_load test &&
#  uc__env &&
#  uc__report
#}

#
