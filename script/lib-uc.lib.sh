#!/usr/bin/env bash

### User-Conf lib-load impl.


## Core-ext

lib_uc_lib__load ()
{
  true "${ENV_SRC:=}"
  true "${ENV_LIB:=}"
  true "${lib_loaded:=}"
}

lib_uc_lib__init ()
{
  sh_fun "${lib_load:-lib_load}" || {
    declare -a lib_uc_dyn=()
    lib_uc__define
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

#lib_uc__exports="core base extra"
#
#lib_uc__declare ()
#{
#  declare -ga lib_uc_dyn=( )
#  SH_DECL[uc_lib:core]="uc_script_load lib_uc_load lib_uc_init"
#}

# Define (or override) lib-* functions with uc-lib-* variants
lib_uc__define ()
{
  local dynfun
  for dynfun in ${us_lib_api:-exists load loaded init require}
  do
    eval "lib_$dynfun () { lib_uc_$dynfun \"\$@\"; }"
    lib_uc_dyn+=( "lib_$dynfun" )
  done
}


## Base

# Test lib exists on PATH and echo source path
lib_uc_exists () # ~ <Name>
{
  test 1 -eq $# || return ${_E_GAE:-193}
  test -z "${libpath_var-}" && {
    lib_uc_path "${1:?}" >/dev/null
    return
  }
  declare -g ${libpath_var:?}=$(lib_uc_path "${1:?}")
}

lib_uc_ids () # ~ <Names...>
{
  test $# -gt 0 || set -- ${lib_loaded:?}
  local lib_name
  for lib_name in "${@:?}"
  do
    echo "${lib_name//[^A-Za-z0-9_]/_}"
  done
}

# XXX: Track <nameid>_script_loaded and set ENV_SRC
uc_script_load () # (scr_ext=sh} ~ <Src-name...>
{
  local scr_name scr_path scr_varn scr_st
  for scr_name in "${@:?}"
  do
    scr_path=$(command -v "$scr_name.${scr_ext:-sh}") ||
      $LOG error ":uc:script-load" "Not found" "$scr_name" 127 || return
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

# Track <nameid>_lib_loaded and set ENV_LIB.
#
# Load sh-libs <Names> from PATH, or load <default-libs>. Loading is two steps:
# sourcing the script, and invoking the lib load hook (if present). The load
# hook return status or 0 is tracked using a variable.
# The routine also populates <ENV-LIB> for every source path loaded, and
# <lib-loaded> with every lib name that correctly loaded. Load hooks can return
# E:retry or E:next to signal that loading failed but other libs can proceed,
# with the status returned only at the end. Other states trigger an abort
# directly after they are recorded.
lib_uc_load () # <Names...>
{
  test -z "${lib_loading:-}" || {
    $LOG alert :uc:lib-load "Recursion" "lib_loading=$lib_loading" \
      ${_E_recursion:-111} ||
    return
  }
  local lib_loading=1
  test $# -gt 0 && {
    test -n "${1-}" || return ${_E_GAE:-193}
  } || set -- ${default_sh_lib:?}
  ! uc_debug || $LOG info ":uc:lib-load" "Resolving lib(s)" "($#) $*"

  local lib_name lib_varn lib_stat lib_path f_lib_load retry
  for lib_name in "${@:?}"
  do
    lib_varn=${lib_name//[^A-Za-z0-9_]/_}
    lib_stat=${lib_varn}_lib_loaded
    test 0 -ne "${!lib_stat:--1}" || {
      ! uc_debug || $LOG debug :uc:lib-load "Skipping loaded" "$_:$lib_name"
      continue
    }
    # Stored status means file already loaded
    # XXX: bats has some debug trap that spoils $_? test "$_" != "-1" || {
    test "-1" != "${!lib_stat:--1}" || {
      # Lookup path to lib
      lib_path=$(command -v "$lib_name.lib.sh") ||
        $LOG error ":uc:lib-load" "Not found" "$lib_name" 127 || return
      # XXX: not the same var.. UC_TOOLS_DEBUG?
      #test -z "${USER_CONF_DEBUG-}" ||
      ! uc_debug ||
        $LOG info ":uc:lib-load:$lib_varn" "Loading" "$lib_path"
      . "$lib_path" ||
        $LOG error ":uc:lib-load" "Sourcing library" "E$?:$lib_name" $? ||
          return
      ENV_LIB="${ENV_LIB:-}${ENV_LIB:+ }$lib_path"
    }
    # Execute load hook if found, and (re)set status
    f_lib_load=${lib_varn}_lib__load
    declare -F $f_lib_load >/dev/null 2>&1 || {
      f_lib_load=${lib_varn}_lib_load
      ! declare -F $f_lib_load >/dev/null 2>&1 || {
        $LOG warn : "Deprecated lib core 'load' hook name" "$f_lib_load"
      }
    }
    ! uc_debug ||
      ! declare -F "$f_lib_load" >/dev/null 2>&1 ||
        $LOG debug : "Running lib 'load' hook" "$lib_name"
    ! declare -F "$f_lib_load" >/dev/null 2>&1 || {
      "$f_lib_load"
    }
    declare -g ${lib_stat}=$?
    lib_loaded="${lib_loaded-}${lib_loaded:+ }$lib_name"
    test 0 -eq ${!lib_stat} && continue
    { test ${_E_next:-196} -eq $_ ||
      test ${_E_retry:-198} -eq $_
    } && retry=true || return $_
  done
  ! ${retry:-false} || return ${_E_retry:-198}
}

# Invoke lib 'init' hook and track result, but only if present. On subsquent
# invocations only missing hooks or non-zero states are tried again. <Names>
# defaults to <lib-loaded>.
lib_uc_init () # ~ [<Names...>]
{
  test -z "${lib_init:-}" || {
    $LOG alert :uc:lib-init "Recursion" "$*:lib_init=$lib_init" \
      ${_E_recursion:-111} ||
    return
  }
  local lib_init="$*" INIT_LOG=${INIT_LOG:-${LOG:?}}
  test $# -gt 0 || set -- ${lib_loaded:?}
  local lib_name lib_varn lib_stat v_lib_init f_lib_init
  for lib_name in "${@:?}"
  do
    lib_varn=${lib_name//[^A-Za-z0-9_]/_}
    lib_stat=${lib_varn}_lib_loaded
    test 0 -eq ${!lib_stat:--1} ||
      $LOG error ":uc:lib-init" "Missing or failed to load" \
        "E${!lib_stat:-unset}:$lib_name" $_ || return
    f_lib_init=${lib_varn}_lib__init
    declare -F $f_lib_init >/dev/null 2>&1 || {
      f_lib_init=${lib_varn}_lib_init
      ! declare -F $f_lib_init >/dev/null 2>&1 || {
        $LOG warn : "Deprecated lib core 'init' hook name (ignored)" "$f_lib_init"
      }
    }
    ! declare -F $f_lib_init >/dev/null 2>&1 || {
      $f_lib_init
    }
    v_lib_init=${lib_varn}_lib_init
    declare -g ${v_lib_init}=$?
    test 0 -eq ${!v_lib_init} || {
      test ${_E_retry:-198} -ne $_ || return $_
      #  $LOG crit :uc:lib-init "Not implemented: pending in lib-init" "" \
      #      ${_E_todo:-125} || return
      $LOG error ":uc:lib-init" "Init hook failed" "E$_:$lib_name" $_
      return
    }
  done
}

# Exactly like lib-loop, except given symbols do not need to exist and are
# skipped silently if missing.
lib_uc_hook () # ~ <Type> <Name-key-suffix> [<Names...>]
{
  lib_loop_require=false lib_uc_loop "$@"
}

lib_uc_islib () # ~ <Name>
{
  lib_uc_loaded "${1:?}" && return
  lib_uc_exists "$_"
}

# Test if all given names loaded correctly.
lib_uc_loaded () # ~ [<Names...>]
{
  test $# -gt 0 || {
    test -n "${lib_loaded:-}" && set -- ${lib_loaded:?} || return ${_E_MA:-194}
  }
  local lib_name lib_varn lib_stat
  for lib_name in "${@:?}"
  do
    lib_varn=${lib_name//[^A-Za-z0-9_]/_}
    lib_stat=${lib_varn}_lib_loaded
    test 0 -eq ${!lib_stat:--1} && { continue; }
    return $_
  done
}

# Go over symbols for lib names and suffix, and either invoke those as functions
# or resolve to values from variables.
# XXX: this is provided as helper, but all of the uc-lib-* functions do their
# own loop implementation. The type 'pairs' is added as a convenient tool to
# inspect lib-load, lib-init states and similar.
lib_uc_loop () # ~ <Type> <Name-key-suffix> [<Names...>]
{
  local hook_tp=${1:-fun} hook_suf=${2:?lib-uc-loop:2:Hook suffix argument}
  shift 2
  test $# -gt 0 || {
    test -n "${lib_loaded:-}" && set -- ${lib_loaded:?} || return ${_E_MA:-194}
  }
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

lib_uc_path ()
{
  command -v "${1:?}".lib.sh
}

# A wrapper for lib-load, that also works inside lib 'load' hooks. Normally
# calls during lib-load (ie. from a load hook) results in recursion, but this
# functions populates LIB_REQ and returns E:retry status in that case. These
# prerequisite names are accumulated and prefixed to the current <names>, libs
# that loaded correctly are filtered out, and lib-load is invoked for the rest
# until either all are loaded or an unexpected status occurs.
lib_uc_require () # ~ <Names...>
{
  test $# -gt 0 || return ${_E_MA:-194}

  test -z "${lib_load-}" || {
    set -- $(for lib_name in "${@:?}"
      do
        lib_varn=${lib_name//[^A-Za-z0-9_]/_}
        lib_stat=${lib_varn}_lib_loaded
        test 0 -eq ${!lib_stat:--1} && continue
        echo "$lib_name"
      done)
    # Pending libs
    LIB_REQ="${LIB_REQ:-}${LIB_REQ:+ }$*"
    test -z "$LIB_REQ" && return || return ${_E_retry:-198}
  }

  lib_loading= lib_load "$@" && return ||
    test ${_E_retry:-198} -eq $? ||
      $LOG error :uc:lib-require "During load" "E$_:$*" $_ || return

  : "${LIB_REQ:?"Expected LIB_REQ (after lib_load '$*')"}"
  until test -z "${LIB_REQ-}"
  do
    $LOG info :uc:lib-require "Required:" "$LIB_REQ:for:$*"
    set -- $LIB_REQ "$@" ; unset LIB_REQ
    set -- $(for lib_name in "${@:?}"
      do
        lib_varn=${lib_name//[^A-Za-z0-9_]/_}
        lib_stat=${lib_varn}_lib_loaded
        test 0 -eq ${!lib_stat:--1} && continue
        echo "$lib_name"
      done | awk '!a[$0]++')
    test $# -eq 0 && return
    $LOG info :uc:lib-require "Pending:" "$*"
    lib_loading= lib_load "$@" && return || {
      test ${_E_retry:-198} -eq $? || return $_
    }
  done
}

# Id: user-conf/0.0.1-dev script/uc-lib.lib.sh
# From: script-mpe/0.0.4-dev src/sh/lib/lib.lib.sh
