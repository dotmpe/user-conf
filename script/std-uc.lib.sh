#!/usr/bin/env bash

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


std_uc_lib__load ()
{
  test -n "${uname-}" || uname="$(uname -s)"

  # The deeper get within subshells, the more likely stdio is re-routed from
  # tty. This test should be performed in the scripts main.
  true "${std_interactive:="std_term 0"}"

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

std_uc_lib__init ()
{
  test -n "${INIT_LOG-}" || return 109
  test -x "$(command -v readlink)" || error "readlink util required for stdio-type" 1
  test -x "$(command -v file)" || error "file util required for stdio-type" 1
  test -n "${LOG-}" && std_lib_log="$LOG" || std_lib_log="$INIT_LOG"
  test -z "${v-}" || verbosity=$v

  test -n "${STD_INTERACTIVE-}" || {
    eval "$std_interactive" && STD_INTERACTIVE=1 || STD_INTERACTIVE=0
  }

  std_uc_env_def
  $INIT_LOG "debug" "" "Initialized std-uc.lib" "$*"
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
  : "${_E_GAE:=193}" # Generic Argument Error.
  # : "${_E_MA:=194}" # Arguments Expected (Missing Argument(s)) Error.
  # See rules
  # E:failure 195: failure, exception; abort
  # E:continue 196: continue with next alt.; skip; keep-going
  # E:stop 197: break; stop
  # E:retry 198: pending; retry later
  # E:limit 199: limit;
  # E:more : more;

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

std_batch_mode ()
{
  test ${STD_BATCH_MODE:-0} -eq 1 -o ${STD_INTERACTIVE:-0} -eq 0
}

# Id: user-conf/0.2.0 script/std-uc.lib.sh
