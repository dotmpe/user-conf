#!/usr/bin/env bash

### Executable script to handle logging

#shellcheck disable=2128 # Using FUNCNAME shortcut to first element on array

# TODO: move all functions to parts or lib

## Shell env defaults
test -d "$HOME/.local/lib/user-conf" && true "${U_C:="$HOME/.local/lib/user-conf"}"
test -d "/usr/local/lib/user-conf" && true "${U_C:="/usr/local/lib/user-conf"}"
test -d "/usr/lib/user-conf" && true "${U_C:="/usr/lib/user-conf"}"
test -d "$HOME/.basher/cellar/packages/user-tools/user-conf/" && true "${U_C:="$HOME/.basher/cellar/packages/user-tools/user-conf"}"
test -d "/src/local/user-conf" && true "${U_C:="/src/local/user-conf"}"

: "${HOST:=${OS_HOSTNAME:-localhost}}"

[ -n "$U_C" ] && [ -d "$U_C" ] || {
  >&2 echo "Unable to find Uc path <$U_C>"
  exit 1
}

# The path to this executable
true "${UC_SELF:="$U_C/tool/sh/log.sh"}"


## Entrypoints if called as script.

uc_log_main_env () # ~ [<Switch>]
{
  case "${1:-}" in
  ( dyn )
        # dump functions and declarations of dynamic setup
        uc_log_init &&
        : "${STDLOG_UC_LEVEL:=6}"
        declare -p uc_log \
          STDLOG_UC_LEVEL \
          UC_LOG_LEVEL \
          UC_SYSLOG_LEVEL &&
        declare -f uc_log uc_syslog_1 \
          syslog_logger_{prifmt,datetime,colorize}_filter \
          stdlog_uc__syslog_colorize syslog_facility_name syslog_level_name \
          stdlog_to_syslog \
          syslog_level_num &&
        echo "declare +x LOG" &&
        echo "declare -- x LOG=uc_log" &&
        echo "declare -- x uc_log=uc_log" &&
        cat <<EOM
        # Defaults:
        # STDLOG_UC_DT    :-1
        # STDLOG_UC_ANSI  :-1
        # STDLOG_UC_PRI   :-1
        # STDLOG_UC_LEVEL :=6
        # STDLOG_UC_EXITS :=5
        # UC_QUIET        :=0
        # UC_SYSLOG_{OFF,LEVEL}
EOM
      ;;

  ( var )
  cat <<EOM
LOG="${LOG:-"$UC_PROFILE_SELF"}"
EOM
    ;;

  ( "" | static )
  cat <<EOM
LOG="${LOG:-"$UC_PROFILE_SELF"}"
EOM
    ;;

   * ) >&2 echo "${ENV_CTX-}:${FUNCNAME}:$1: unrecognized switch"
  esac
}

uc_main_log () # ~ (env|[log] <log-args>)
{
  # Best effort to offer a logger interface to shell profile scripts.
  test -z "${UC_LOG_FAIL:-}" && {

    # FIXME: unset for Dash
    : "${SHELL:=}"
    uc_log_init

  } || {

    # Fall-back is nothing and quietly pass execution back to shell.
    test -n "${UC_DIAG:-}" || exit 0

    # Unless diagnostics is actively on, if so put everything on stderr.
    uc_faillog ()
    {
      printf "${RED:-}UC profile faillog %s: [%s] %s %s %i${NORMAL:-}" "$1" "$2" \
        "${3:-"(no message)"}" "${4:+"<$4>"}" "${5:-0}" >&2
    }
    uc_log=uc_faillog
  }

  # TODO: Check arguments, if libs are loaded
  #uc_fun args_uc__argc && { args_uc__argc :uc-main-log $# gt || return; }

  # Check arguments, perform, exit.
  test "$1" = "log" && shift
  test "$1" = "note" && { shift; set -- notice "$@"; }
  case "$1" in

    emerg|alert|crit|err|warning|notice|info|debug|panic|error|warn ) ;;

    * ) echo ":log()" "Expected priority, found '$1' ('$*')" >&2; return 60 ;;
  esac

  "${uc_log:?}" "$@"
}

# Setup uc_log handler using syslog-uc.lib (and INIT_LOG but not LOG)
uc_log_init () # ~
{
  # Get log key base. This is the first part a tag/facility prefixed to each
  # output.
  test -z "${log_key:-}" || UC_LOG_BASE="$log_key" # XXX: BWC log-key env

  [[ ${UC_LOG_BASE:+set} ]] || {
    : "$(ps -q $$ -o ppid=)"
    : "${_# }"
    "${UC_LOG_BASE_LONG:-true}" "$_" &&
      : "${UC_LOG_BASE:="$USER@$HOST:$PWD:$(basename -- "$SHELL")[$_]"}" ||
      : "${UC_LOG_BASE:="$(basename -- "$SHELL")[$_]"}"
  }

  # Verbosity is overriden from generic user-env setting
  test -z "${verbosity:-${v:-}}" || UC_LOG_LEVEL="${verbosity:-$v}" # XXX: BWC

  . "${UC_LIB_BASE:-"$U_C/script"}/args-uc.lib.sh"
  args_uc_lib_load=$?
  . "${UC_LIB_BASE:-"$U_C/script"}/stdlog-uc.lib.sh" &&
  stdlog_uc_lib__load || return
  stdlog_uc_lib_load=0
  INIT_LOG=stderr_log

  # Make Uc-profile source all its parts
  [ 0 = "${UC_PROFILE_READY-}" ] || {
    #. "${U_C:?}/tool/sh/log-init.sh"
    . "${U_C}/script/uc-profile.lib.sh" &&
    uc_profile_boot_parts || return
  }

  # XXX: a bit of deferred uc-profile setup here
  local load_log_level
  ! "${LOG_DEBUG:-false}" && load_log_level=4 || load_log_level=${UC_LOG_LEVEL:?}
  v=${load_log_level} LOG=$INIT_LOG uc_profile_load_lib || {
    >&2 echo "Failed uc-profile-load-lib E$?"
    return 1
  }

  # Setup logger (but not LOG)
  { uc_fun uc_log || syslog_uc_init uc_log
    } &&
  : "${uc_log:=uc_log}"

  #args_uc__argc $# ||
  [ $# -eq 0 ] ||
    _uconf_shell_log error ":log.sh:init" "$FUNCNAME: Expected no arguments $- 0:$0 *:$* ($#) (ignored)"
}

# Actual entry point for executable script
case "$0" in

  -* ) ;;

  */$(basename "${UC_SELF?}") )

      case "${1:-}" in

        ( "" ) exit 1 ;;

        ( env ) shift; uc_log_main_env "$@"; exit $? ;;
        ( log | * )
          _Sh_Fun_Exists _DEBUG || _UConf_Shell_Log_init

          uc_main_log "$@"; exit $? ;;
      esac

    ;;

  * )
esac

#
