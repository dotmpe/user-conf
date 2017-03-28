#!/usr/bin/env bats

base=boilerplate
load helper
init


@test "bash/env.sh - should load, and print generic bash/env notice" {
  run . ./bash/env.sh
  { test "${lines[*]}" = "[user-conf] Using generic bash/env" &&
    test_ok_nonempty; } || stdfail
}


