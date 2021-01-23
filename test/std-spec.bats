#!/usr/bin/env bats

load helper
base=std
init
. $lib/std-uc.lib.sh
. $lib/str-uc.lib.sh


@test "${lib}/${base} - std_v <n> should return 1 if <n> <= <verbosity>. No output." {

  verbosity=1
  run std_v 1
  test_ok_empty || stdfail 1.1
  run std_v 2
  { test ${status} -eq 1 &&
    test -z "${lines[*]}"; } || stdfail 1.2
  run std_v 0
  test_ok_empty || stdfail 1.3

  verbosity=6
  run std_v 7
  { test ${status} -eq 1 && test -z "${lines[*]}"; } || stdfail 2.1
  run std_v 1
  test_ok_empty || stdfail 2.2
  run std_v 0
  test_ok_empty || stdfail 2.3

  verbosity=0
  run std_v 0
  test_ok_empty || stdfail 3.1
  run std_v 1
  test ${status} -eq 1
  test -z "${lines[*]}"
}


@test "${lib}/${base} - std_exit <n> should call exit <n> if <n> is an integer number or return 1. No output. " {

  exit(){ echo 'exit '$1' ok'; }

  run std_exit
  test ${status} -eq 1
  test -z "${lines[*]}"

  run std_exit 1
  test ${status} -eq 0
  test "exit 1 ok" = "${lines[*]}"

  run std_exit 0
  test ${status} -eq 0
  test "exit 0 ok" = "${lines[*]}"
}


@test "${lib}/${base} - error should echo at verbosity>=3" {

  verbosity=2
  run info "test"
  test ${status} -eq 0
  test -z "${lines[*]}"

  real_exit=ext
  exit(){ echo 'exit '$1' call'; command exit $1; }

  verbosity=4
  run error "error"
  test ${status} -eq 0
  fnmatch "*error*" "${lines[*]}"

  verbosity=2
  run error "test" 1
  test ${status} -eq 1
  test "exit 1 call" = "${lines[*]}"

  run error "test" 0
  test ${status} -eq 0
  test "exit 0 call" = "${lines[*]}"
}


@test "${lib}/${base} - info should echo at verbosity>=6" {

  verbosity=4
  run info "test" 0
  test ${status} -eq 0
  test -z "${lines[*]}"

  verbosity=5
  run info "test info exit" 3
  test ${status} -eq 3
  test -z "${lines[*]}"

  verbosity=6
  run info "test info exit" 3
  test ${status} -eq 3
  fnmatch "*test info exit*" "${lines[*]}"

  verbosity=6
  run info "test info exit" 0
  test ${status} -eq 0
  fnmatch "*test info exit*" "${lines[*]}"

  verbosity=5
  run info "test" 0
  test ${status} -eq 0
  test -z "${lines[*]}"

  exit(){ echo 'exit '$1' call'; command exit $1; }
  verbosity=6
  run info "test" 0
  test ${status} -eq 0
  fnmatch "*exit 0 call" "${lines[*]}"
}

