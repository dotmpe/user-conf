#!/usr/bin/env bats

base=../test/helper.bash
load helper
init
. $lib/std.lib.sh
. $lib/str.lib.sh


@test "${lib}/${base} - is_skipped: returns 0 if ENV_SKIP=1 or 1, no output" {

    run is_skipped foo
    {
      test "${status}" = 1 && test "${lines[*]}" = ""
    } || stdfail 1

    run bash -c '. '${lib}/${base}' && FOO_SKIP=1 is_skipped foo'
    {
      test "${status}" = 0 && test "${lines[*]}" = ""
    } || stdfail 1

    FOO_SKIP=1
    run is_skipped foo
    {
      test "${status}" = 0 && test "${lines[*]}" = ""
    } || stdfail 2
}

@test "${lib}/${base} - current_test_env no args: echos valid env (TEST_ENV, host or user name), returns 0" {

    run current_test_env
    { test "${status}" = 0 && {
        test "${lines[0]}" = "$TEST_ENV" ||
        test "${lines[0]}" = "$hostnameid" ||
        test "${lines[0]}" = "$(whoami)"
      }
    } || stdfail
}

@test "${lib}/${base} - check_skipped_envs: returns 0 or 1, no output" {

    run check_skipped_envs foo bar baz
    test "${status}" = 0
    test "${lines[*]}" = "" # No output
    test "${#lines[@]}" = "0" # No output

    run check_skipped_envs $(current_test_env) || test -z "Should have skipped for env"
    test "${status}" = 1 || test -z "Should have failed: default envs is all envs"
    test "${lines[*]}" = ""
}

@test "${lib}/${base} - check_skipped_envs: check current env" {
    run check_skipped_envs "$(current_test_env)"
    test "${status}" -ne 0 || \
      fail "Should have set {ENV}_SKIP=1 for proper test! do it now. "
}

