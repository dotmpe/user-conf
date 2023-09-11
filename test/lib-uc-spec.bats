load helper

setup ()
{
  DEBUG=true UC_DEBUG=true
  v=7
  . script/lib-uc.lib.sh
  lib_uc_lib__load &&
  lib_uc_lib__init
}

@test "After initializing lib-uc" {
  
  stderr echo starting: $lib_loaded stat=$argv_uc_lib_loaded

  #"lib-load is a function"
  run sh_fun lib_load
  test_ok_empty || stdfail 1.

  #"that sources .lib.sh files"
  run lib_load argv-uc
  test_ok_empty || stdfail 2.1.

  stderr declare -f sh_fun
  ! sh_fun argv_uc__argc || stdfail argv-uc.lib already loaded

  lib_load argv-uc
  stderr echo loaded: $lib_loaded stat=$argv_uc_lib_loaded
  stderr echo LIB $ENV_LIB
  stderr echo SRC $ENV_SRC
  declare -f argv_uc__argc
  stderr declare -f argv_uc__argc
  run sh_fun argv_uc__argc

  test_ok_empty || stdfail 2.2.

  #"and calls its 'load' hook"
}

#@test "Lib load or init hook shall not call lib-load"
#@test "Lib load hooks may call lib-require"
#@test "Lib init hooks may call lib-require"
#@test "lib-require loads lib(s) and prerequisites"
