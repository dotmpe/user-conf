#!/usr/bin/env bash

### Executable script to handle logging

# TODO: move all functions to parts or lib

## Shell env defaults
test -d "/usr/lib/user-conf" && true "${U_C:="/usr/lib/user-conf"}"
test -d "/usr/local/lib/user-conf" && true "${U_C:="/usr/local/lib/user-conf"}"
test -d "$HOME/.local/lib/user-conf" && true "${U_C:="$HOME/.local/lib/user-conf"}"
test -d "/src/local/user-conf" && true "${U_C:="/src/local/user-conf"}"

test -d "$U_C" || {
  echo "Unable to find Uc path <$U_C>" >&2
  exit 1
}

true "${UC_LIB_PATH:="$U_C/script"}"

test -d "$UC_LIB_PATH" || {
  echo "Unable to find Uc lib path <$UC_LIB_PATH>" >&2
  exit 1
}

# The path to this executable
true "${UC_SELF:="$U_C/tools/sh/log.sh"}"


## Entrypoints if called as script.

uc_log_env () # ~
{
  echo $(<<EOM
LOG=${LOG:-"$UC_PROFILE_SELF"}"
uc_log="$LOG"
EOM
  )
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
  : "${UC_LOG_BASE:="$USER $(basename -- "$SHELL")[$$] uc-profile"}"
  { uc_profile_load_lib || return
    } &&
  { uc_func uc_log || syslog_uc_init uc_log
    } &&
  : "${uc_log:=uc_log}" &&
  argv_uc__argc :log-init $# || return
}

# Helper to source libs only once
uc_profile_load_lib ()
{
  test -n "${UC_PROFILE_SRC_LIB-}" || {
    uc_profile_source_lib || return
  }
}

# Source all libs
uc_profile_source_lib () # ~
{
  UC_PROFILE_SRC_LIB=1

  # This is not so nice but there's too many functions involved.
  # XXX: Keep this file stable. Move essentials here, later probably?
  # Should maybe mark some and keep (working) caches
  #  Or mark these libs as 'global'
  . $UC_LIB_PATH/str-uc.lib.sh &&
  . $UC_LIB_PATH/argv-uc.lib.sh &&
  . $UC_LIB_PATH/stdlog-uc.lib.sh &&
  stdlog_uc_lib_load &&
  . $UC_LIB_PATH/ansi-uc.lib.sh &&
  ansi_uc_lib_load &&
  . $UC_LIB_PATH/syslog-uc.lib.sh &&
  syslog_uc_lib_load &&

  ansi_uc_lib_init &&
  #stdlog_uc_lib_init &&
  #syslog_uc_lib_init &&

  UC_PROFILE_SRC_LIB=0
}

uc_func ()
{
  argv_uc__argc :uc-func $# eq 1 || return
  test "$(type -t "$1")" = "function"
}

uc_cmd ()
{
  argv_uc__argc :uc-cmd $# eq 1 || return
  test -x "$(which "$1")"
}

uc_var ()
{
  argv_uc__argc :uc-var $# eq 1 || return
  local val upd

  # Force update or try existing value first
  fnmatch "* $1 *" " $UC_VAR_PDNG " && {
    uc_update "$1"
    upd=1
  }

  val="${!1-}"
  test -z "$val" -a -z "${upd-}" && {
    uc_var_update "$1"
    val="${!1-}"
  }
  test -n "$val" || return

  echo "$val"
}

uc_signal_exit ()
{
  local code=${1:-${?:-0}}
  test $code -eq 0 && return 1
  test $code -gt 128 -a $code -lt 162 || return
  exit_signal=$(( $code - 128 ))

  signal_names='HUP INT QUIT ILL TRAP ABRT EMT FPE KILL BUS SEGV SYS PIPE ALRM TERM URG STOP TSTP CONT CHLD TTIN TTOU IO XCPU XFSZ VTALRM PROF WINCH INFO USR1 USR2'
  set -- $signal_names
  signal_name=${!exit_signal}
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
