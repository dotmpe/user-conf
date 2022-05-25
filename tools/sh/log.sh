#!/usr/bin/env bash

### Executable script to handle logging

# TODO: move all functions to parts or lib

## Shell env defaults
test -d "$HOME/.local/lib/user-conf" && true "${U_C:="$HOME/.local/lib/user-conf"}"
test -d "/usr/local/lib/user-conf" && true "${U_C:="/usr/local/lib/user-conf"}"
test -d "/usr/lib/user-conf" && true "${U_C:="/usr/lib/user-conf"}"
test -d "$HOME/.basher/cellar/packages/user-tools/user-conf/" && true "${U_C:="$HOME/.basher/cellar/packages/user-tools/user-conf"}"
test -d "/src/local/user-conf" && true "${U_C:="/src/local/user-conf"}"

test -d "$U_C" || {
  echo "Unable to find Uc path <$U_C>" >&2
  exit 1
}

true "${UC_LIB_PATH:="$U_C/script"}"

# The path to this executable
true "${UC_SELF:="$U_C/tools/sh/log.sh"}"


## Entrypoints if called as script.

uc_log_env () # ~
{
  cat <<EOM
LOG="${LOG:-"$UC_PROFILE_SELF"}"
uc_log="$LOG"
EOM
  exit
}

uc_main_log () # ~ (env|[log] <log-args>)
{
  # Best effort to offer a logger interface to shell profile scripts.
  test -z "${UC_LOG_FAIL:-}" && {

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

  # Check arguments, if libs are loaded
  uc_func argv_uc__argc && { argv_uc__argc :uc-main-log $# gt || return; }

  # Check arguments, perform, exit.
  test "$1" = "log" && shift
  test "$1" = "note" && { shift; set -- notice "$@"; }
  case "$1" in

    emerg|alert|crit|err|warning|notice|info|debug|panic|error|warn ) ;;

    * ) echo ":log()" "Expected priority, found '$1' ('$*')" >&2; return 60 ;;
  esac

  $uc_log "$@"
}

# Setup uc_log handler using syslog-uc.lib
uc_log_init () # ~
{
  test -z "${log_key:-}" || UC_LOG_BASE="$log_key" # XXX: BWC
  test -z "${verbosity:-${v:-}}" || UC_LOG_LEVEL="${verbosity:-$v}" # XXX: BWC
  : "${UC_LOG_BASE:="$USER $(basename -- "$SHELL")[$$] uc-profile"}"
  { uc_profile_load_lib || return
    } &&
  { uc_func uc_log || syslog_uc_init uc_log
    } &&
  : "${uc_log:=uc_log}" &&
  argv_uc__argc :log-init $# || return
}

# Actual entry point for executable script
case "$0" in

  -* ) ;;

  */$(basename "$UC_SELF") )

      case "${1:-}" in

        ( "" ) exit 1 ;;

        ( env ) shift; uc_log_env "$@"; exit $? ;;
        ( log | * ) uc_main_log "$@"; exit $? ;;
      esac

    ;;

  * ) ;;
esac

#
