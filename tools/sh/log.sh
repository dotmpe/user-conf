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

  # Check arguments, if libs are loaded
  uc_fun args_uc__argc && { args_uc__argc :uc-main-log $# gt || return; }

  # Check arguments, perform, exit.
  test "$1" = "log" && shift
  test "$1" = "note" && { shift; set -- notice "$@"; }
  case "$1" in

    emerg|alert|crit|err|warning|notice|info|debug|panic|error|warn ) ;;

    * ) echo ":log()" "Expected priority, found '$1' ('$*')" >&2; return 60 ;;
  esac

  $uc_log "$@"
}

# Setup uc_log handler using syslog-uc.lib (and INIT_LOG but not LOG)
uc_log_init () # ~
{
  # Get log key base. This is the first part a tag/facility prefixed to each
  # output.
  test -z "${log_key:-}" || UC_LOG_BASE="$log_key" # XXX: BWC
  : "${UC_LOG_BASE:="$USER $(basename -- "$SHELL")[$$] uc-profile"}"

  # Verbosity is overriden from generic user-env setting
  test -z "${verbosity:-${v:-}}" || UC_LOG_LEVEL="${verbosity:-$v}" # XXX: BWC

  . "${UC_LIB_PATH:-"$U_C/script"}/args-uc.lib.sh"
  args_uc_lib_load=$?
  . "${UC_LIB_PATH:-"$U_C/script"}/stdlog-uc.lib.sh" &&
  stdlog_uc_lib__load || return
  stdlog_uc_lib_load=0
  INIT_LOG=stderr_log

  # Make Uc-profile source all its parts
  test "${UC_PROFILE_LOADED-}" = "0" || {
    #. "${U_C:?}/tools/sh/log-init.sh"
    . "${U_C}/script/uc-profile.lib.sh" &&
    uc_profile_boot_parts || return
  }

  # XXX: a bit of deferred uc-profile setup here

  local load_log_level
  ! "${LOG_DEBUG:-false}" && load_log_level=4 || load_log_level=${UC_LOG_LEVEL:?}
  v=${load_log_level} LOG=$INIT_LOG uc_profile_load_lib || return

  # Setup logger (but not LOG)
  { uc_fun uc_log || syslog_uc_init uc_log
    } &&
  true "${uc_log:=uc_log}"
  args_uc__argc :log-init $#
}

# Actual entry point for executable script
case "$0" in

  -* ) ;;

  */$(basename "$UC_SELF") )

      case "${1:-}" in

        ( "" ) exit 1 ;;

        ( env ) shift; uc_log_env "$@"; exit $? ;;
        ( log | * )
          uc_main_log "$@"; exit $? ;;
      esac

    ;;

  * )
esac

#
