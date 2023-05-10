#!/usr/bin/env bash

### User-Conf lib-load impl.


## Core-ext

uc_lib__load ()
{
  true "${lib_loaded:=}"
}

uc_lib__init ()
{
  sh_fun "${lib_load:-lib_load}" || {
    declare -a uc_lib_dyn=()
    uc_lib__define
  }
  test -z "${SCRIPTPATH:-}" || {
    local scrp
    for scrp in ${SCRIPTPATH//:/ }
    do
      append_path "$scrp"
    done
    export PATH
  }
}

#uc_lib__exports="core base extra"
#
#uc_lib__declare ()
#{
#  declare -ga uc_lib_dyn=( )
#  SH_DECL[uc_lib:core]="uc_script_load uc_lib_load uc_lib_init"
#}

# Define (or override) lib-* functions with uc-lib-* variants
uc_lib__define ()
{
  local dynfun
  for dynfun in ${us_lib_api:-exists load loaded init require}
  do
    eval "lib_$dynfun () { uc_lib_$dynfun \"\$@\"; }"
    uc_lib_dyn+=( "lib_$dynfun" )
  done
}


## Base

# Test lib exists in scriptpath
uc_lib_exists () # ~ <Name>
{
  command -v "${1:?}".lib.sh
}

uc_lib_ids ()
{
  test $# -gt 0 || set -- ${lib_loaded:?}
  local lib_name
  for lib_name in "${@:?}"
  do
    echo "${lib_name//[^A-Za-z0-9_]/_}"
  done
}

# XXX: Track <nameid>_script_loaded and set ENV_SRC
uc_script_load ()
{
  local scr_name scr_path scr_varn scr_st
  for scr_name in "${@:?}"
  do
    scr_path=$(command -v "$scr_name.sh") || {
      $LOG error ":uc:script-load" "Not found" "$scr_name" $?
      return
    }
    scr_varn=${scr_name//[^A-Za-z0-9_]/_}
    scr_st=${scr_varn}_script_loaded
    test 0 -eq ${!scr_st:--1} && {
        ! uc_debug ||
          $LOG debug :uc:script-load "Skipping sourced script" "$scr_name"
      } || {
        ! uc_debug ||
          $LOG info :uc:script-load "Sourcing script" "$scr_name"
        . "$scr_path"
        eval ${scr_st}=$?
        ENV_SRC="${ENV_SRC:-}${ENV_SRC:+ }$scr_path"
        test 0 -eq ${!scr_st:?} || {
          $LOG warn :uc:script-load "Script source" "E${!scr_st}:$scr_name" ${!scr_st} || return
        }
      }
  done
}

# Load sh-lib on PATH
uc_lib_load ()
{
  test -z "${lib_load:-}" || return ${_E_recursion:-111}
  local lib_load=1
  test $# -gt 0 && {
    test -n "${1-}" || return ${_E_GAE:-193}
  } || set -- ${default_sh_lib:?}

  local lib_name lib_varn lib_stat lib_path f_lib_load
  for lib_name in "${@:?}"
  do
    lib_varn=${lib_name//[^A-Za-z0-9_]/_}
    lib_stat=${lib_varn}_lib_loaded
    test 0 -eq ${!lib_stat:--1} && { continue; }
    lib_path=$(command -v "$lib_name.lib.sh") ||
      $LOG error ":uc:lib-load" "Not found" "$lib_name" $? || return
    # XXX: not the same var.. UC_TOOLS_DEBUG?
    #test -z "${USER_CONF_DEBUG-}" ||
    ! uc_debug ||
      $LOG info ":uc:lib-load:$lib_varn" "Loading" "$lib_path"
    . "$lib_path" && {
      ENV_LIB="${ENV_LIB:-}${ENV_LIB:+ }$lib_path"
      f_lib_load=${lib_varn}_lib__load
      type $f_lib_load >/dev/null 2>&1 || {
        f_lib_load=${lib_varn}_lib_load
        ! type $f_lib_load >/dev/null 2>&1 || {
          $LOG warn : "Deprecated lib core 'load' hook name" "$f_lib_load"
        }
      }
      ! type $f_lib_load >/dev/null 2>&1 || {
        $f_lib_load
      }
    } || {
      eval ${lib_stat}=$?
      test ${_E_retry:-198} -eq ${!lib_stat} && return $_
      $LOG error ":uc:lib-load" "Loading shell library" "E$_:$lib_name" $_
      return
    }
    eval ${lib_stat}=0
    lib_loaded="${lib_loaded-}${lib_loaded:+ }$lib_name"
  done
}

uc_lib_init ()
{
  test -z "${lib_init:-}" || return ${_E_recursion:-111}
  local lib_init=1
  test $# -gt 0 || set -- ${lib_loaded:?}
  local lib_name lib_varn lib_stat lib_init f_lib_init
  for lib_name in "${@:?}"
  do
    lib_varn=${lib_name//[^A-Za-z0-9_]/_}
    lib_stat=${lib_varn}_lib_loaded
    test 0 -eq ${!lib_stat:--1} || {
      $LOG error ":uc:lib-init" "Missing or failed to load" \
        "E${!lib_stat:-unset}:$lib_name" $_
      return
    }
    lib_init=${lib_varn}_lib_init
    f_lib_init=${lib_varn}_lib__init
    type $f_lib_init >/dev/null 2>&1 || {
      f_lib_load=${lib_varn}_lib_init
      ! type $f_lib_init >/dev/null 2>&1 || {
        $LOG warn : "Deprecated lib core 'init' hook name (ignored)" "$f_lib_init"
      }
    }
    ! type $f_lib_init >/dev/null 2>&1 || {
      $f_lib_init
    }
    eval ${lib_init}=$?
    test 0 -eq ${!lib_init} || {
      test ${_E_retry:-198} -ne $_ || return $_
      #  $LOG crit :uc:lib-init "Not implemented: pending in lib-init" "" \
      #      ${_E_todo:-125} || return
      $LOG error ":uc:lib-init" "Init hook failed" "E$_:$lib_name" $_
      return
    }
  done
}

# Test if $lib_loaded all sourced/loaded OK. To see which, use $lib_loaded.
uc_lib_loaded ()
{
  test $# -gt 0 || set -- ${lib_loaded:?}
  local lib_name lib_varn lib_stat
  for lib_name in "${@:?}"
  do
    lib_varn=${lib_name//[^A-Za-z0-9_]/_}
    lib_stat=${lib_varn}_lib_loaded
    test 0 -eq ${!lib_stat:--1} && { continue; }
    return $_
  done
}

# Exactly like lib-loop, except given symbols do not need to exist and are
# skipped silently if missing.
uc_lib_hook () # ~ <Type> <Name-key-suffix> <Names...>
{
  lib_loop_require=false uc_lib_loop "$@"
}

# Go over symbols generated from suffix and loaded lib names, and either echo
# or invoke those variable(s) and function(s) respectively.
uc_lib_loop () # ~ <Type> <Name-key-suffix> <Names...>
{
  local hook_tp=${1:-fun} hook_suf=${2:?}
  shift 2
  test $# -gt 0 || set -- ${lib_loaded:?}
  local lib_name lib_varn lib_hook
  for lib_name in "${@:?}"
  do
    lib_varn=${lib_name//[^A-Za-z0-9_]/_}
    lib_hook=${lib_varn}${hook_suf}
    case "$hook_tp" in
      ( fun )
          sh_fun "${lib_hook}" || {
            ${lib_loop_require:-true} && return 1 || continue
          }
          $lib_hook || return
        ;;
      ( var ) ${lib_loop_require:-true} &&
          echo "${!lib_hook:?}" ||
          echo "${!lib_hook:-}"
        ;;
      ( pairs ) ${lib_loop_require:-true} &&
          echo "$lib_name ${!lib_hook:?}" ||
          echo "$lib_name ${!lib_hook:-}"
        ;;
      ( * ) return 1 ;;
    esac
  done
}

uc_lib_require () # ~ <Libs...>
{
  #local uc_lib_require=1
  test $# -gt 0 || return ${_E_MA:-194}
  #test -z "${lib_init:-}" || {
  #  return ${_E_retry:-198}
  #  return ${_E_todo:-125}
  #}

  test -z "${lib_load-}" || {
    set -- $(for lib_name in "${@:?}"
      do
        lib_varn=${lib_name//[^A-Za-z0-9_]/_}
        lib_stat=${lib_varn}_lib_loaded
        test 0 -eq ${!lib_stat:--1} && continue
        echo "$lib_name"
      done)
    test $# -eq 0 && return
    # Pending libs
    LIB_REQ="${LIB_REQ:-}${LIB_REQ:+ }$*"
    return ${_E_retry:-198}
  }
  lib_load "$@" && return ||
    test ${_E_retry:-198} -eq $? ||
      $LOG error :uc:lib-require "During load" "E$_:$*" $_ || return

  : "${LIB_REQ:?"Expected LIB_REQ"}"
  until test -z "${LIB_REQ-}"
  do
    $LOG info :uc:lib-require "Pending:" "$LIB_REQ:for $*"
    set -- $LIB_REQ "$@" ; unset LIB_REQ
    lib_load "$@" && return || {
      test ${_E_retry:-198} -eq $? || return $_
    }
  done
}

# Id: user-conf/0.0.1-dev script/uc-lib.lib.sh
# From: script-mpe/0.0.4-dev src/sh/lib/lib.lib.sh
