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
_uc_env_ () # @uc/base
{
: src "uc-env.sh"
  local args
  case "${*:?${ENV_CTX:-$0[$$]}:uc-env Arguments expected}" in
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
      uc_script_load "${2}.inc.sh"
    ;;
  ( -q | --query )
      if_ok "$(declare -F ${2:?}:bash)"
    ;;
  ( -r | --require )
      : about 'Check for or resolve given part name(s)'
      : param '~ ~ <Part-name ...>'
      : ${2:?Part name(s) expected, $ENV_CTX:$FUNCNAME:$1}
    ;;
   * ) $LOG error :uc-env "No such action" "$1" ${_E_nsa:-68}
  esac
}

_uc_env_load ()
{
  false
}

if_ok ()
{
  return
}


# Main entry (see user-script.sh for boilerplate)

# Normalize scriptname (ignore extension in command name)
: "${0##*\/}"
: "${_%.sh}"
! case "$_" in
  ( uc-env ) SCRIPTNAME=uc-env.sh
    ;;
    * ) false
esac || {
  #user_script_load || ${uc_stat:-exit} $?
  ## Pre-parse arguments
  #if_ok "$(user_script_defarg "$@")" &&
  #eval "set -- $_" &&
  #script_run "$@"
  _uc_env_ "$@"
}
