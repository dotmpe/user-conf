#!/bin/sh

## std: dealing with the shell's stdio decriptors

# std-uc: this offers a lot of support to uc-profile, although the short logging
# format is not as much used there. For profiles it is most important to try
# as best as possible to load all parts.

# XXX: any non-stdio things here should probably be in stdlog.lib. But I better
# sync all those libs in that case.

# This should deal with std:io, std:err idioms.
# Also feeling like std:fail should provide support for std:argv and old std:log
# stuff.
# Comments in std:log
#
# Normally scripts are allowed to handle non-zero status by passing them via
# return, and handle them at any point, or end with a non-zero exit.
#
# I think std.lib should provide the idioms for that as well. Maybe std:status.


std_uc_lib_load ()
{
  true "${uname:="$(uname -s | tr '[:upper:]' '[:lower:]')"}"

  # The deeper get within subshells, the more likely stdio is re-routed from
  # tty. This test should be performed in the scripts main.
  true "${std_interactive:=std_term 0}"

  # Result of std_interactive test. Defaulted in init.
  #STD_INTERACTIVE=[01]

  # Default show notices and above
  true "${UC_DEFAULT_VERBOSITY:=5}"

  true "${STD_E:=GE SH CE CN IAE ESOOR}"
  true "${STD_E_SIGNALS:="HUP INT QUIT ILL TRAP ABRT IOT BUS FPE KILL USR1 SEGV\
 USER2 PIPE ALRM TERM STKFLT CHLD CONT STOP TSTP TTIN TTOU URG XCPU XFSZ VTALRM\
 PROF WINCH IO POLL PWR LOST"}"

  true "${verbosity:=$UC_DEFAULT_VERBOSITY}"
}

std_uc_lib_init ()
{
  test -n "${INIT_LOG-}" || return 109
  test -x "$(which readlink)" || error "readlink util required for stdio-type" 1
  test -x "$(which file)" || error "file util required for stdio-type" 1
  test -n "${LOG-}" && std_lib_log="$LOG" || std_lib_log="$INIT_LOG"
  test -z "${v-}" || verbosity=$v

  true ${STD_INTERACTIVE:=`eval "$std_interactive"; printf $?`}

  std_uc_env_def
  $INIT_LOG debug "" "Initialized std-uc.lib" "$0"
}


std_uc_env_def ()
{
  local key

  # Set defaults for status codes
  # XXX: need better variable name convention if integrated with +U-s
  # Like STD_* for software defined and _STD_ for user-defined or local script
  # static variables. See also stdlog discussion on more idiomatic flows.

  for key in ${STD_E} ${STD_E_SIGNALS}
  do
    vref=UC_DEFAULT_${key^^}
    declare $vref=false
    #declare $vref=true
    #val=${!vref-} || continue
    #echo "val='$val'" >&2
  done

  # nr. should not already be used in context.
  : "${_E_GAE:=177}" # Generic Argument Error.
}

# Test if all [given] stdio are at terminal.
std_term () # ~ [0] [1] [2]...
{
  test $# -gt 0 || set -- 0 1 2
  test -n "$*" || return ${_E_GAE}

  local tty
  while test $# -gt 0
  do
    test -t $1 || tty=false
    shift
  done
  ${tty:-true}
}

log_src_id_var()
{
  test -n "${log_key-}" || {
    test -n "${stderr_log_channel-}" && {
      log_key="$stderr_log_channel"
    } || {
      test -n "${base-}" || {
        base=\$\$:\$scriptname
      }
      test -n "$base" && {
        test -n "${scriptext-}" || scriptext=.sh
        log_key=\$base\$scriptext
      } || echo "Cannot get var-log-key" 1>&2;
    }
  }
}

log_src_id()
{
  eval echo \"$log_key\"
}

# stdio helper functions
log()
{
  test -n "${log_key:-}" || log_src_id_var
  printf -- "[$(log_src_id)] $1\n"
}

err()
{
  # TODO: turn this on and fix tests warn "err() is deprecated, see stderr()"
  log "$1" 1>&2
  test -z "${2-}" || exit $2
}

stderr()
{
  case "$(echo $1 | tr 'A-Z' 'a-z')" in
    warn*|err*|notice ) err "$1: $2" "${3-}" ;;
    * ) err "$2" "${3-}" ;;
  esac
}

# std-v <level>
# if verbosity is defined, return non-zero if <level> is below verbosity treshold
std_v()
{
  test -z "$verbosity" && return || {
    test $verbosity -ge $1 && return || return 1
  }
}

std_exit () # [exit-at-level]
{
  test -n "${1-}" || return 0
  test "$1" != "0" && return 0 || exit $1
}

emerg()
{
  std_v 1 || { std_exit ${2-} && return 0; }
  stderr "Emerg" "$1" ${2-}
}
crit()
{
  std_v 2 || { std_exit ${2-} && return 0; }
  stderr "Crit" "$1" ${2-}
}
error()
{
  std_v 3 || { std_exit ${2-} && return 0; }
  stderr "Error" "$1" ${2-}
}
warn()
{
  std_v 4 || { std_exit ${2-} && return 0; }
  stderr "Warning" "$1" ${2-}
}
note()
{
  std_v 5 || { std_exit ${2-} && return 0; }
  stderr "Notice" "$1" ${2-}
}
std_info()
{
  std_v 6 || { std_exit ${2-} && return 0; }
  stderr "Info" "$1" ${2-}
}
debug()
{
  std_v 7 || { std_exit ${2-} && return 0; }
  stderr "Debug" "$1" ${2-}
}

std_batch_mode ()
{
  test ${STD_BATCH_MODE:-0} -eq 1 -o ${STD_INTERACTIVE:-0} -eq 0
}

# Id: user-conf/0.2.0 script/std-uc.lib.sh
