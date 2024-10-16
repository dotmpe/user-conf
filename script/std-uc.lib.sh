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
  true &&
  if_ok "${uname:="$(uname -s)"}" &&
  if_ok "${scriptname:=${SCRIPTNAME:-$(basename -- "$0")}}" || return

  # The deeper get within subshells, the more likely stdio is re-routed from
  # tty. This test should be performed in the scripts main.
  true "${std_interactive:="std_term 0"}"

  # Result of std_interactive test. Defaulted in init.
  #STD_INTERACTIVE=[01]

  # Default show notices and above
  true "${UC_DEFAULT_VERBOSITY:=5}"

  true "${STD_E_SIGNALS:="HUP INT QUIT ILL TRAP ABRT IOT BUS FPE KILL USR1 SEGV\
 USER2 PIPE ALRM TERM STKFLT CHLD CONT STOP TSTP TTIN TTOU URG XCPU XFSZ VTALRM\
 PROF WINCH IO POLL PWR LOST"}"

  true "${verbosity:=$UC_DEFAULT_VERBOSITY}"
}

std_uc_lib__init ()
{
  test -z "${std_uc_lib_init-}" || return $_
  [[ "${INIT_LOG-}" ]] || return 102
  [[ -x "$(command -v readlink)" ]] || error "readlink util required for stdio-type" 1
  [[ -x "$(command -v file)" ]] || error "file util required for stdio-type" 1
  [[ "${LOG-}" ]] && std_lib_log="$LOG" || std_lib_log="$INIT_LOG"
  [[ -z "${v-}" ]] || verbosity=$v

  [[ "${STD_INTERACTIVE-}" ]] || {
    eval "$std_interactive" && STD_INTERACTIVE=1 || STD_INTERACTIVE=0
  }

  std_uc_env_def
  ${INIT_LOG:?} "debug" "" "Initialized std-uc.lib" "$*" $?
}


std_uc_env_def ()
{
  # user scripts may fail without blaming either script or user. Or, decide one
  # of the two and this should be based on the source of the inputs Is the
  # cause user arguments or data, or was the fault in supposed finalized and
  # static script? This can be contextually nuanced, and irrelevant too.
  : "${_E_fail:=1}"
  # 1: fail: generic non-success status, not an error per se
  : "${_E_script:=2}"
  # 2: script: error caused by broken syntax or script misbehavior
  : "${_E_user:=3}"
  # 3: user: usage error or faulty data

  : "${_E_nsk:=67}"
  # 67: nsk: no such key
  : "${_E_nsa:=68}"
  # 68: nsa: no such action

  #: "${_E_cont:=100}"
  : "${_E_recursion:=111}" # unwanted recursion detected

  : "${_E_no_file:=124}" # no-such-file(set): file missing or nullglob
  : "${_E_not_exec:=126}" # NEXEC not-executable
  : "${_E_not_found:=127}" # NSFC no-such-file-or-command
  # XXX: 128 is free?

  : "${_E_sighup:=129}" # 1:
  : "${_E_sigint:=130}" # 2: response to ctrl-c
  : "${_E_sigquit:=131}" # 3:
  : "${_E_sigill:=132}" # 4: illegal instruction?
  : "${_E_sigtrap:=133}" # 5: trace/breakpoint trap

  # 128+(1--64) is mapped for signals (see trap -l), ie. `kill -1 $PID` produces
  # exit status 129, inserting Ctrl-C in a shell terminal produces exit 131,
  # etc. On debian linux last mapped number is 192: RTMAX (ie. 128+64).

  : "${_E_GAE:=193}" # Generic Argument Error.
  : "${_E_MA:=194}" # Arguments Expected (Missing Argument(s)) Error.
  # See rules
  # E:continue 195: unfinished; in loop or batch sequence keep going until break
  # or done.
  # E:next     196: like 195 but fail/skip iso. error, continue with next alt.
  : "${_E_next:=196}"
  # E:stop     197:
  : "${_E_stop:=197}" # abort or fatal step
  # E:retry    198: pending; not 195/196 but can retry later this loop/batch
  # E:break    limit    199: limit; like 198 but some throttling was initiated as well
  : "${_E_done:=200}"
  # E:done     200: break; OK, but if loop/batch then terminate, stop when first convenient
  # E:more     201: more; partially completed ?
}

# Helper to generate true or false command, and produce syntax error on
# invalid value. XXX: see std-bit. Value should be 1 or 0.
std_bool () # ~ <Cmd ...> # Print true or false, based on command status
{
  "$@" && printf true || {
    [[ 1 -eq $? ]] || BOOL= : ${BOOL:?Boolean status expected: E$_: $*}
    printf false
  }
}
# Test if all [given] stdio are at terminal.
std_term () # ~ [0] [1] [2]...
{
  [[ $# -gt 0 ]] || set -- 0 1 2
  [[ "$*" ]] || return ${_E_GAE}

  local tty
  while [[ $# -gt 0 ]]
  do
    [[ -t $1 ]] || tty=false
    shift
  done
  ${tty:-true}
}

std_batch_mode () # (STD-BATCH-MODE) ~ <...>
{
  [[ ${STD_BATCH_MODE:-0} -eq 1 || ${STD_INTERACTIVE:-0} -eq 0 ]]
}

# Boolean-bit: validate 0/1, or return NZ for other arguments. This uses
# std-bool with the test command. Test returns a for 0 (true) or 1 (false),
# and 2 for sytax error and std-bool produces a syntax error as well. This
# catches other values than 0|1 and returns E:GAE instead. If empty values
# should imply either 0 or 1, set the second parameter.
std_bit () # ~ <Bit-value> [<If-empty=2>]
{
  [[ $# -eq 1 && 2 -gt "${1:-${2:-2}}" ]] || return ${_E_GAE:-193}
  std_bool test 0 -eq "${1:?}"
}

# XXX: match command status against globspec.
std_ifstat () # ~ <Spec> <Cmd ...>
{
  "${@:2}"
  str_globmatch "$?" "$1"
}

std_noerr () # ~ <Cmd ...> # Silence stderr
{
  "$@" 2>/dev/null
}

std_noout () # ~ <Cmd...> # Silence stdout
{
  "$@" >/dev/null
}

# See also 'not'
std_nz () # ~ <Cmd ...> # Invert status, fail (only) if command returned zero-status
{
  ! "$@"
}

std_quiet () # ~ <Cmd...> # Silence verbose log and warnings (stderr)
{
  "$@" 2>/dev/null
}
# alias: std-noerr

std_silent () # ~ <Cmd...> # Silence all output (std{out,err})
{
  "$@" >/dev/null 2>&1
}

# XXX: rename these or deprecate: std-v*

std_verbose () # ~ <Message ...> # Print message
{
  stderr echo "$@" || return 3
}

std_v1c () # ~ <Cmd ...> # Wrapper that echoes both command and status
{
  : param "<Cmd ...>"
  : note "Strictly for debugging of script branches (or DEBUG, DIAG mode etc)"
  stderr echo "Running command: $*"
  "$@"
  stderr_stat $? "$@"
}

std_v_exit () # ~ <Cmd ...> # Wrapper to command that exits verbosely
{
  : param "<Cmd ...>"
  "$@"
  stderr_exit $?
}

std_v_stat ()
{
  : param "<Cmd ...>"
  "$@"
  stderr_stat $? "$@"
}

std_vs () # ~ <Message ...> # Print message, but pass previous status code
{
  : about "Print message, but pass previous status code"
  : param "<Message ...>"
  local stat=$?
  stderr echo "$@" || return 3
  return $stat
}

stderr () # ~ <Cmd <...>>
{
  "$@" >&2
}

stderr_exit () # ~ <Status=$?> <...> # Verbosely exit passing status code,
# with status message on stderr. See also std-v-exit.
{
  local stat=${1:-$?}
  stderr echo "$([[ 0 -eq $stat ]] &&
    printf 'Exiting\n' ||
    printf 'Exiting (status %i)\n' $stat)" "$stat"
  exit $stat
}

stderr_v_exit () # ~ <Message> [<Status>] # Exit shell after printing message
{
  local stat=$?
  stderr echo "$1" || return 3
  exit ${2:-$stat}
}

# Like stderr-v-exit, but exits only if status is given explicitly, or else
# if previous status was non-zero.
#sh_fun_decl stderr_ \
#  local stat=\$?\;\
#  stderr echo \"\$1\" "||" return 3\;\
#  test -z \"\${2:-}\" "&&" test 0 -eq \"\$stat\" "||" exit \$_\;
stderr_ ()
{
  local stat=$?;
  stderr echo "$1" || return 3;
  [[ -z "${2:-}" && 0 -eq "$stat" ]] || exit $stat
}

# Show whats going on during sleep, print at start and end. Makes it easier to
# find interrupt points for sensitive scripts. Verbose sleep prints to stderr
# and does not listen to v{,verbosity} but does have a verbose mode toggle var
# sleep-v.
stderr_sleep_int ()
{
  local last=$_
  : "${sleep_q:=$(bool not ${sleep_v:-true})}"
  ! ${sleep_v:-true} ||
    printf "> sleep $*$([[ -z "$last" ]] || printf " because $last...")" >&2
  fun_wrap command sleep "$@" || {
    [[ 130 -eq $? ]] && {
      "$sleep_q" ||
        echo " aborted (press again in ${sleep_itime:-1}s to exit)" >&2
      command sleep ${sleep_itime:-1} || return
      return
    } || return $_
  }
  ! ${sleep_v:-true} ||
    echo " ok, continue run" >&2
}

stderr_stat () # ~ <Status> <Label-str ..>
{
  local last=$_ stat=${1:-$?} ref=${*:2}
  : "${ref:-$last}"
  [[ 0 -eq $stat ]] &&
    printf "OK '%s'\\n" "$ref" ||
    printf "Fail E%i: '%s'\\n" "$stat" "$ref"
  return $stat
}

# Id: user-conf/0.2.0 script/std-uc.lib.sh
