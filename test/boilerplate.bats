#!/usr/bin/env bats

base=boilerplate
load helper
init
#init_bin


@test "${bin} -vv -n help" {
  skip "envs: envs=$envs FIXME is hardcoded in test/helper.bash current_test_env"
  check_skipped_envs || \
    skip "TODO envs $envs: implement bin (test) for env"
  run $BATS_TEST_DESCRIPTION
  test_ok_empty || stdfail
}

@test "${lib}/${base} - function should ..." {
  check_skipped_envs || \
    skip "TODO envs $envs: implement lib (test) for env"
  run function args
  test_ok_nonempty || stdfail
}

