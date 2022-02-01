#!/usr/bin/env bats

load helper
init
uc_lib=${lib}/user-conf
scriptname=us-resolve.bats
. ${uc_lib}/lib.sh

setup ()
{
  UC_QUIET=1
  UC_SYSLOG_OFF=1
}

@test "uc resolve-conf" {

  TODO
  run uc__resolve
  test_ok_empty || stdfail
}


@test "uc resolve-env" {

  # Baseline
  run uc__resolve_env
  test_nok_empty || stdfail 1.1

  run uc__resolve_env NAME
  test_ok_nonempty "${UC_CONFIG_NAME}" || stdfail 2.3

  run uc__resolve_env ext install
  test_ok_nonempty "${UC_CONFIG_INSTALL_EXT}" || stdfail 1.3

  UC_RESOLVE_PREFIX="foo1 "
  FOO1_FOO="Value 1"
  run uc__resolve_env foo
  test_ok_nonempty "Value 1" || stdfail 2.1

  UC_RESOLVE_PREFIX="foo1 bar1 "
  FOO1_BAR1_FOO="Value 2"
  run uc__resolve_env foo
  test_ok_nonempty "Value 2" || stdfail 2.2

  FOO1_BAR1_FOO2_BAR_FOO="Value 3"
  run uc__resolve_env foo bar foo2
  test_ok_nonempty "Value 3" || stdfail 2.3

  run uc__resolve_env foo bar baz
  test_ok_nonempty "Value 2" || stdfail 2.4

  FOO1_BAR1_BAR_FOO="Value 4"
  run uc__resolve_env foo bar baz
  test_ok_nonempty "Value 4" || stdfail 2.5

  FOO1_BAR1_BAZ_BAR_FOO="Value 5"
  run uc__resolve_env foo bar baz
  test_ok_nonempty "Value 5" || stdfail 2.6
}


@test "uc resolve-path" {

  run uc__resolve_path
  test_nok_empty || stdfail 1

  run uc__resolve_path nopath
  test_nok_empty || stdfail 2

  run uc__resolve_path script
  test_ok_nonempty "script/" || stdfail 3

  unset status
  run uc__resolve_path script user-conf
  test_ok_nonempty "script/user-conf/" || stdfail 4

  unset status
  run uc__resolve_path foo user-conf
  test_nok_empty || stdfail 5

  unset status
  run uc__resolve_path script foo user-conf
  test_nok_nonempty "script/" || stdfail 6
}

@test "uc config" {

  cd ~/.conf
  run uc__config NAME.u-c install
  test_ok_nonempty "install/local.u-c" || stdfail 1

  #run uc__config os-uc.lib.sh script
  #test_ok_nonempty "script/os-uc.lib.sh" || stdfail 2
}

#
