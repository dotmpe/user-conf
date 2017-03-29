#!/usr/bin/env bats

load helper
load util-ex.inc

init
source $lib/util.lib.sh
#source $lib/main.sh


# XXX: clean me up to a test-helper func
test_inc="$lib/util.lib.sh $lib/test/helper.bash $lib/test/util-ex.inc.bash"
test_inc_bash="source $(echo $test_inc | sed 's/\ / \&\& source /g')"
test_inc_sh=". $(echo $test_inc | sed 's/\ / \&\& . /g')"


# util / Try-Exec

@test "$lib test run test functions to verify" "" "" {

  run mytest_function
  test $status -eq 0
  test "${lines[0]}" = "mytest"

  run mytest_load
  test $status -eq 0
  test "${lines[0]}" = "mytest_load"
}

@test "$lib test run non-existing function to verify" {

  run sh -c 'no_such_function'
  test $status -eq 127

  case "$(uname)" in
    Darwin )
      test "sh: no_such_function: command not found" = "${lines[0]}"
      ;;
    Linux )
      test "${lines[0]}" = "sh: 1: no_such_function: not found"
      ;;
  esac

  run bash -c 'no_such_function'
  test $status -eq 127
  test "${lines[0]}" = "bash: no_such_function: command not found"
}


