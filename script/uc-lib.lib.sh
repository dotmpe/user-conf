#!/bin/sh

uc_lib_init ()
{
  uc_func "${lib_load:-lib_load}" || {
    lib_load=uc_lib_load
    lib_exists=uc_lib_exists
    lib_loaded=uc_lib_loaded
    lib_require=uc_lib_loaded
  }
}

uc_lib_export ()
{
  export -f uc_script_load uc_lib_load uc_lib_init
}

# Test lib exists in scriptpath
uc_lib_exists () # ~ <Name>
{
  command -v "${1:?}".lib.sh
}

uc_script_load ()
{
  local scr_path scr_varn scr_st
  while test $# -gt 0
  do
    scr_path=$(command -v "$1.sh") || {
      $LOG error ":uc:script-load" "Not found" "$1" $?
      return
    }
    scr_varn=${1//-/_}
    scr_st=${scr_varn}_script_loaded
    test 0 -eq ${!scr_st:--1} || {
      . "$scr_path"
      eval ${scr_st}=$?
      ENV_SRC="${ENV_SRC:-}${ENV_SRC:+ }$scr_path"
      test 0 -eq ${!scr_st:?} || return
    }
    shift
  done
}

# Load sh-lib on PATH
uc_lib_load ()
{
  true "${lib_loaded:=}"
  test -n "${__load_lib-}" || local __load_lib=1
  test -n "${1-}" || set -- ${default_sh_lib:?}

  local lib_varn lib_stat lib_path f_lib_load
  while test $# -gt 0
  do
    lib_varn=${1//-/_}
    lib_stat=${lib_varn}_lib_loaded
    test 0 -eq ${!lib_stat:--1} && { shift; continue; }
    lib_path=$(command -v "$1.lib.sh") || {
      $LOG error ":uc:lib-load" "Not found" "$1" $?
      return
    }
    # XXX: not the same var.. UC_TOOLS_DEBUG?
    test -z "${USER_CONF_DEBUG-}" ||
      $LOG info ":uc:lib-load:$lib_varn" "Loading" "$lib_path"
    . "$lib_path" && {
      ENV_LIB="${ENV_LIB:-}${ENV_LIB:+ }$lib_path"
      f_lib_load=${lib_varn}_lib_load
      ! type $f_lib_load >/dev/null 2>&1 || {
        $f_lib_load
      }
    } || {
      eval ${lib_stat}=$?
      $LOG error ":uc:lib-load" "Sourcing" "$1" $?
      return
    }
    eval ${lib_stat}=0
    lib_loaded="${lib_loaded-}${lib_loaded:+ }$1"
    shift
  done
}

uc_lib_init ()
{
  test -n "${1-}" || set -- ${lib_loaded:?}

  local lib_varn lib_stat lib_init f_lib_init
  while test $# -gt 0
  do
    lib_varn=${1//-/_}
    lib_stat=${lib_varn}_lib_loaded
    test 0 -eq ${!lib_stat:--1} || {
      $LOG error ":uc:lib-init" "Missing or failed to load" "E${!lib_stat}:$1" $?
      return
    }
    lib_init=${lib_varn}_lib_initialized
    f_lib_init=${lib_varn}_lib_init
    ! type $f_lib_init >/dev/null 2>&1 || {
      $f_lib_init
    }
    eval ${lib_init}=$?
    test ${!lib_init} -eq 0 || {
      $LOG error ":uc:lib-init" "Init failed" "E${!lib_init}:$1" $?
      return
    }
    shift
  done
}

uc_lib_loaded ()
{
  local lv llv
  while test $# -gt 0
  do
    lv=${1//-/_}
    llv=${lv}_lib_loaded
    test 0 -eq ${!llv:--1} && { shift; continue; }
    return 1
  done
}


# Id: user-conf/0.0.1-dev script/uc-lib.lib.sh
# From: script-mpe/0.0.4-dev src/sh/lib/lib.lib.sh
