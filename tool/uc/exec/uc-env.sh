#!/usr/bin/env bash

# XXX: should really want to compile this entire script, remove all deps
#us-env -r user-script || ${uc_stat:-exit} $?
#uc_script_load user-script || ${us_stat:-exit} $?

uc_version=v0.2.1-dev

uc_env__grp=uc

uc_env_name="User configuration environment"
uc_env_version=v0.0.0-dev
uc_env_defcmd=short
uc_env_maincmds=declare,help,knows,load,query,require
uc_env_shortdescr=

# TODO: transpile function from parts, see tool/uc/part/-env,func,uc.sh
uc-env ()
{
  : source "uc-env.sh"
  #[[ ${uc_node[*]+set} ]] || uc_env_loadenv ||
  local args
  case "${*:?}" in
  ( -h|-?|--help )
      cat <<EOM
Command
  uc-env <...>

Usage options:
  -d|--known    Dynamic define from source+meta
  -D|--declare  Provide source from source+meta

EOM
    ;;
  esac &&
  args=$( getopt -o q:d:l:L:r:cu \
    --long query:,known:,load:,lookup:,require:,cycle,update -- "$@" ) &&
  eval "set -- $args" &&
  case "${1:?}" in
  ( -D | --declare )
    ;;
  ( -E | --exec )
    ;;
  ( -d | --knows )
    ;;
  ( -l | --load )
      #uc_script_load "$2"
    ;;
  ( -q | --query )
      if_ok "$(declare -F ${2:?}):bash"
    ;;
   * ) $LOG error :uc-env "No such action" "$1" ${_E_nsa:-68}
  esac
}

if_ok ()
{
  return
}

# Check if given argument equals zeroth argument.
# Unlike when calling script-name, this will not pollute the environment.
script_isrunning () # [SCRIPTNAME] ~ <Scriptname> [<Name-ext>]# argument matches zeroth argument
{
  [[ $# -ge 1 && $# -le 2 ]] || return ${_E_GAE:-3}
  [[ ${SCRIPTNAME:+set} ]] && {
    [[ $SCRIPTNAME = "$1" ]]
    return
  }
  [[ $# -eq 2 ]] && SCRIPT_BASEEXT="${2:?}"
  script_name &&
  [[ "${SCRIPTNAME:?Expected SCRIPTNAME after script_name}" = "$1" ]] || {
    [[ $# -lt 2 ]] || unset SCRIPT_BASEEXT
    unset SCRIPTNAME
    return 1
  }
}
# Copy

# Main entry (see user-script.sh for boilerplate)

# Normalize scriptname (ignore extension in command name)
: "${0##*\/}"
: "${_%.sh}"
case "$_" in
  ( uc-env ) SCRIPTNAME=uc-env.sh
esac

! script_isrunning "uc-env.sh" || {
  #user_script_load || ${uc_stat:-exit} $?
  ## Pre-parse arguments
  #if_ok "$(user_script_defarg "$@")" &&
  #eval "set -- $_" &&
  #script_run "$@"
  uc-env "$@"
}
