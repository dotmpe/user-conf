#!/usr/bin/env bash

### User-Conf lib-load impl.


## Core-ext

lib_uc_lib__load ()
{
  true "${ENV_SRC:=}"
  true "${ENV_LIB:=}"
  true "${lib_loaded:=}"
  true "${lib_uc_ext:=.lib.sh}"
  true "${lib_uc_kin:=_lib}" # key infix: <libid><kin>_{loaded,init,_load}

  lib_uc_fun=$(echo lib_uc_{exists,has_init,hook,ids,init,init_all,initialized,initialized_all,islib,load,loaded,loaded_all,loop,path,require} uc_script_load)
}

lib_uc_lib__init ()
{
  sh_fun "${lib_load:-lib_load}" || {
    typeset -a lib_uc_dyn=()
    lib_uc__define
  }
  [[ -z "${SCRIPTPATH-}" ]] || {
    local scrp
    for scrp in ${SCRIPTPATH//:/ }
    do
      append_path "$scrp"
    done
    export PATH
  }

  ! { "${DEBUG:-false}" || "${DEV:-false}" || "${INIT:-false}"; } ||
  ${LOG:?} notice ":lib-uc:lib-init" "Initialized lib-uc.lib"
}


#lib_uc__exports="core base extra"
#lib_uc_core__fun=
#
#lib_uc__typeset ()
#{
#  typeset -ga lib_uc_dyn=( )
#  SH_DECL[uc_lib:core]="uc_script_load lib_uc_load lib_uc_init"
#}

# Define (or override) lib-* functions with uc-lib-* variants
lib_uc__define ()
{
  local ref from_key to_key
  for ref in ${us_lib_api:-assert:loaded_all exists load loaded:loaded_all init initialized:initialized_all require}
  do
    from_key=${ref#*:}
    to_key=${ref%:*}
    eval "lib_$to_key () { lib_uc_$from_key \"\$@\"; }"
    lib_uc_dyn+=( "lib_$to_key" )
  done
}


## Base

# Test lib exists
lib_uc_exists () # ~ <Name>
{
  [[ 1 -eq $# ]] || return ${_E_GAE:-193}
  [[ -z "${libpath_var-}" ]] && {
    lib_uc_path "${1:?}" >/dev/null
    return
  }
  typeset -g ${libpath_var:?}=$(lib_uc_path "${1:?}")
}

lib_uc_has_init () # ~ <Name>
{
  : "${1//[^A-Za-z0-9_]/_}${lib_uc_kin:-_lib}__init"
  typeset -F "$_" >/dev/null 2>&1
}

# Exactly like lib-loop, except given symbols do not need to exist and are
# skipped silently if missing.
lib_uc_hook () # ~ <Type> <Name-key-suffix> [<Names...>]
{
  lib_loop_require=false lib_uc_loop "$@"
}

lib_uc_ids () # ~ <Names...>
{
  [[ $# -gt 0 ]] || set -- ${lib_loaded:?}
  local lib_name
  for lib_name in "${@:?}"
  do
    echo "${lib_name//[^A-Za-z0-9_]/_}"
  done
}

# Invoke lib 'init' hook and track result, but only if present. On subsquent
# invocations only missing hooks or non-zero states are tried again. <Names>
# defaults to <lib-loaded>.
lib_uc_init () # ~ [<Names...>]
{
  [[ -z "${lib_init-}" ]] || {
    $LOG alert :uc:lib-init "Recursion" "$*:lib_init=$lib_init" \
      ${_E_recursion:-111} ||
    return
  }
  local lib_init="$*" INIT_LOG=${INIT_LOG:-${LOG:?}}
  [[ $# -gt 0 ]] || set -- ${lib_loaded:?}
  local lib_name lib_varn lib_stat v_lib_init f_lib_init
  for lib_name in "${@:?}"
  do
    lib_varn=${lib_name//[^A-Za-z0-9_]/_}
    lib_stat=${lib_varn}${lib_uc_kin:-_lib}_load
    [[ 0 -eq ${!lib_stat:--1} ]] ||
      $LOG error ":uc:lib-init" "Missing or failed to load" \
        "E${!lib_stat:-unset}:$lib_name" ${!lib_stat:-1} || return
    f_lib_init=${lib_varn}${lib_uc_kin:-_lib}__init
    v_lib_init=${lib_varn}${lib_uc_kin:-_lib}_init
    ! typeset -F $f_lib_init >/dev/null 2>&1 || {
      ! uc_debug ||
        $LOG debug : "Running lib 'init' hook" "$lib_name"
      $f_lib_init
    }
    typeset -g ${v_lib_init}=$?
    [[ 0 -eq ${!v_lib_init} ]] || {
      [[ ${_E_retry:-198} -ne ${!v_lib_init} ]] || return ${!v_lib_init}
      #  $LOG crit :uc:lib-init "Not implemented: pending in lib-init" "" \
      #      ${_E_todo:-125} || return
      $LOG error ":uc:lib-init" "Init hook failed" "E$_:$lib_name" ${!v_lib_init}
      return
    }
  done
}

# requires sys.lib:filter_args
lib_uc_init_all () # ~ <Names...>
{
  local pending lk=${lk:-}:uc:init-all
  lib_uc_require "$@" ||
    $LOG error "$lk" "Failure loading libs" "E$?:$*" $? || return
  if_ok "$(filter_args lib_uc_has_init "$@")" &&
  set -- $_ &&
  [[ 0 -eq $# ]] && return
  while true
  do
    if_ok "$(filters_args "not lib_uc_initialized" "$@")" &&
    set -- $_ || return
    [[ 0 -lt $# ]] || break
    pending=$#
    INIT_LOG=$LOG lib_uc_init "$@" || {
      sys_astat -eq ${_E_retry:-198} && {
        set -- $(filter_args "not lib_uc_initialized" "$@") &&
        [[ $pending -gt $# ]] || {
          set -- "${@:2}" "$1"
        }
        continue
      } ||
        $LOG error "$lk" "Failure initializing libs" "E$?:$lib_loaded" $? ||
          return
    }
  done
}

lib_uc_initialized () # ~ <Name>
{
  [[ $# -eq 1 ]] || return ${_E_GAE:-193}
  : "${1//[^A-Za-z0-9_]/_}${lib_uc_kin:-_lib}_init"
  [[ 0 -eq ${!_:--1} ]]
}

lib_uc_initialized_all () # ~ [<Names...>]
{
  [[ $# -gt 0 ]] || {
    [[ "${lib_loaded-}" ]] && set -- $lib_loaded || return ${_E_MA:-194}
  }
  local lib_name lib_varn lib_istat
  for lib_name in "${@:?}"
  do
    lib_varn=${lib_name//[^A-Za-z0-9_]/_}
    lib_istat=${lib_varn}${lib_uc_kin:-_lib}_init
    [[ 0 -eq ${!lib_istat:--1} ]] && { continue; }
    return ${!lib_istat:--1}
  done
}

lib_uc_islib () # ~ <Name>
{
  lib_uc_loaded "${1:?"$(sys_exc lib-uc:islib@_1 "Libname expected")"}" && return
  lib_uc_exists "$_"
}

# Track <nameid>_lib_load and set ENV_LIB.
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
  [[ -z "${lib_loading-}" ]] || {
    $LOG alert :uc:lib-load "Recursion" "lib_loading=$lib_loading" \
      ${_E_recursion:-111} ||
    return
  }
  local lib_loading=1
  [[ $# -gt 0 ]] && {
    [[ "${1-}" ]] || return ${_E_GAE:-193}
  } || set -- ${default_sh_lib:?}
  ! uc_debug || $LOG info ":uc:lib-load" "Resolving lib(s)" "($#) $*"

  local lib_name lib_varn lib_stat lib_path f_lib_load retry
  for lib_name in "${@:?}"
  do
    lib_varn=${lib_name//[^A-Za-z0-9_]/_}
    lib_stat=${lib_varn}${lib_uc_kin:-_lib}_load
    [[ 0 -ne "${!lib_stat:--1}" ]] || {
      ! uc_debug || $LOG debug :uc:lib-load "Skipping loaded" "$lib_name"
      continue
    }
    # Stored status means file already loaded
    # XXX: bats has some debug trap that spoils $_? test "$_" != "-1" || {
    [[ "-1" != "${!lib_stat:--1}" ]] || {
      # Lookup path to lib
      lib_path=$(command -v "$lib_name${lib_uc_ext:-.lib.sh}") ||
        $LOG error ":uc:lib-load" "Not found" "$lib_name" 127 || return
      # XXX: not the same var.. UC_TOOLS_DEBUG?
      #test -z "${USER_CONF_DEBUG-}" ||
      ! uc_debug || $LOG info ":uc:lib-load:$lib_varn" "Loading" "$lib_path"
      . "$lib_path" ||
        $LOG error ":uc:lib-load" "Sourcing library" "E$?:$lib_name" $? ||
          return
      ENV_LIB="${ENV_LIB:-}${ENV_LIB:+ }$lib_path"
    }
    # Execute load hook if found, and (re)set status
    f_lib_load=${lib_varn}${lib_uc_kin:-_lib}__load
    ! typeset -F "$f_lib_load" >/dev/null 2>&1 || {
      ! uc_debug ||
        $LOG debug : "Running lib 'load' hook" "$lib_name"
      "$f_lib_load"
    }
    typeset -g ${lib_stat}=$?
    lib_loaded="${lib_loaded-}${lib_loaded:+ }$lib_name"
    [[ 0 -eq ${!lib_stat} ]] && continue
    [[ ${_E_next:-196} -eq ${!lib_stat} || ${_E_retry:-198} -eq ${!lib_stat} ]] && retry=true || return ${!lib_stat}
  done
  ! "${retry:-false}" || return ${_E_retry:-198}
}

lib_uc_loaded () # ~ <Name>
{
  [[ $# -eq 1 ]] || return ${_E_GAE:-193}
  : "${1//[^A-Za-z0-9_]/_}${lib_uc_kin:-_lib}_load"
  [[ 0 -eq ${!_:--1} ]]
}

# Test if all given names loaded correctly
lib_uc_loaded_all () # ~ [<Names...>]
{
  [[ $# -gt 0 ]] || {
    [[ "${lib_loaded-}" ]] && set -- $lib_loaded || return ${_E_MA:-194}
  }
  local lib_name lib_varn lib_stat
  for lib_name in "${@:?}"
  do
    lib_varn=${lib_name//[^A-Za-z0-9_]/_}
    lib_stat=${lib_varn}${lib_uc_kin:-_lib}_load
    [[ 0 -eq ${!lib_stat:--1} ]] && continue
    return ${!lib_stat:--1}
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
  [[ $# -gt 0 ]] || {
    [[ "${lib_loaded-}" ]] && set -- $lib_loaded || return ${_E_MA:-194}
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
  command -v -- "${1:?}${lib_uc_ext:-.lib.sh}"
}

# A wrapper for lib-load, that also works inside lib 'load' hooks. Normally
# calls during lib-load (ie. from a load hook) results in recursion, but this
# functions populates LIB_REQ and returns E:retry status in that case. These
# prerequisite names are accumulated and prefixed to the current <names>, libs
# that loaded correctly are filtered out, and lib-load is invoked for the rest
# until either all are loaded or an unexpected status occurs.
lib_uc_require () # ~ <Names...>
{
  [[ $# -gt 0 ]] || return ${_E_MA:-194}

  [[ ${lib_load-} ]] && {
    # Already in load call; list unloaded libs and set as pending
    if_ok "$(filter_args "not lib_uc_loaded" "$@")" &&
    set -- $_ || return
    # Add pending libs and return
    LIB_REQ="${LIB_REQ:-}${LIB_REQ:+ }$*"
    [[ -z "$LIB_REQ" ]] && return || return ${_E_retry:-198}
  }

  lib_loading= lib_load "$@" && return ||
    sys_astat -eq ${_E_retry:-198} ||
      $LOG error :uc:lib-require "During load" "E$?:$*" $? || return

  : "${LIB_REQ:?"Expected LIB_REQ (after lib_load '$*')"}"
  until [[ -z "${LIB_REQ-}" ]]
  do
    $LOG info :uc:lib-require "Required:" "$LIB_REQ:for:$*"
    set -- $LIB_REQ "$@" ; unset LIB_REQ
    set -- $(filter_args "not lib_uc_loaded" "${@:?}" | awk '!a[$0]++')
    [[ $# -eq 0 ]] && return
    $LOG info :uc:lib-require "Pending:" "$*"
    lib_loading= lib_load "$@" && return || {
      sys_astat -eq ${_E_retry:-198} || return $?
      # Continue until LIB_REQ stays empty after lib-load...
    }
  done
}

# Same as lib files, but track <nameid>_script_load and ENV_SRC.
# And no hooks. See user-script:load
uc_script_load () # (scr_ext=sh} ~ <Src-name...>
{
  local scr_name scr_path scr_varn scr_st lk=${lk-}:uc:script-load
  for scr_name in "${@:?}"
  do
    scr_path=$(command -v "$scr_name.${scr_ext:-sh}") ||
      $LOG error "$lk" "Not found" "E127:$scr_name" 127 || return
    scr_varn=${scr_name//[^A-Za-z0-9_]/_}
    scr_st=${scr_varn}_script_load
    [[ 0 -eq ${!scr_st:--1} ]] && {
      ! uc_debug ||
        $LOG debug "$lk" "Skipping sourced script" "$scr_name"
    } || {
      ! uc_debug ||
        $LOG info "$lk" "Sourcing script" "$scr_name"
      lk=$lk:$scr_name \
      . "$scr_path"
      eval ${scr_st}=$?
      ENV_SRC="${ENV_SRC:-}${ENV_SRC:+ }$scr_path"
      [[ 0 -eq ${!scr_st:?} ]] || {
        $LOG warn "$lk" "Script source" "E${!scr_st}:$scr_name" ${!scr_st} || return
      }
    }
  done
}

# Id: user-conf/0.0.1-dev script/uc-lib.lib.sh
# From: script-mpe/0.0.4-dev src/sh/lib/lib.lib.sh
