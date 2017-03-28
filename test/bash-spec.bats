#!/usr/bin/env bats

base=boilerplate
load helper
init


@test "bash/env.sh - should load, and print generic bash/env notice" {
  run . ./bash/env.sh
  { test "${lines[*]}" = "[user-conf] Using generic bash/env" &&
    test_ok_nonempty; } || stdfail
}


@test "bash/alias - should load, print nothing" {
  run . ./bash/alias
  { test_ok_empty; } || stdfail
}


@test "bash/default.rc - should load, print nothing" {
  run . ./bash/default.rc
  { test_ok_empty; } || stdfail
}


@test "bash/profile - should load, print nothing" {
  run . ./bash/profile
  { test_ok_empty; } || stdfail
}


