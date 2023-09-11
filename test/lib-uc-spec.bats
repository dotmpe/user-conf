load helper
#init

setup ()
{
  DEBUG=true UC_DEBUG=true
  v=7
  unset -f lib_load
  . script/lib-uc.lib.sh
  lib_uc_lib__load &&
  lib_uc_lib__init || return
  export PATH=$PATH:test/var/lib/sh
  # stderr echo "After initializing lib-uc"
}

@test "lib-load is a function" {
  run sh_fun lib_load
  test_ok_empty
}

@test "that sources .lib.sh files" {
  run lib_load argv-uc
  test $v -le 4 && {
      test_ok_empty || stdfail 2.1.
    } ||
      test_ok_nonempty || stdfail 2.1.
}

@test "and tracks lib names, sources and status" {
  lib_load argv-uc
  test "$lib_loaded" = "argv-uc"
  test "$argv_uc_lib_loaded" = "0"
  # FIXME: why does above work but below not. Var name doesnt seem to matter
  # values seem to get set, but after lib-load suddenly its empty
  stderr declare -p ENV_LIB
  #test -n "$ENV_LIB"

  lib_load example-empty
  test "$lib_loaded" = "argv-uc example-empty"

  lib_load example-load-hook
}

@test "that sources .lib.sh files (II)" {
  lib_load example-load-hook
  sh_fun example_load_hook_lib__load

  lib_load example-init-hook
  sh_fun example_init_hook_lib__init


  #! sh_fun argv_uc__argc || stdfail argv-uc.lib already loaded
  lib_load argv-uc
  #declare -f argv_uc__argc
  #stderr declare -f argv_uc__argc

  #"and calls its 'load' hook" {
}

@test "Lib load or init hook shall not call lib-load" {

  # lib-load tracks lib-loading to prevent recursion, indicated by status 111
  lib_loading=x
  run lib_uc_load xxx
  test_nok_empty &&
  test "$status" = 111
  unset lib_loading

  TODO
}

#@test "Lib load hooks may call lib-require"
#@test "Lib init hooks may call lib-require"
#@test "lib-require loads lib(s) and prerequisites"
