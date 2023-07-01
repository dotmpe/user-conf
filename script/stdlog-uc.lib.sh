#!/usr/bin/env bash

### A simple 'logger' interface for shell use

# stdlog lines are almost syslog events, except where syslog has facility tags,
# stdlog has a context that may be one or a list of any system ID like filename,
# path, variable, flag, return code or other numerical, but also maybe even URN
# or URL
#
# This sh-lib generates a stdlog env/arg interface wrapper for syslog-uc.lib.
# It creates one on lib-init by default

# and it provides a set of functions for each severity level which may just
# pass a message and an optional status code.


stdlog_uc_lib__load ()
{
  lib_require argv-uc || return

  # Like verbosity but for handlers in this lib
  true "${STDLOG_UC_LEVEL:=6}" # Info
  # XXX: Determines return status of log statement
  true "${STDLOG_UC_EXITS:=3}" # Warning
  # Default level for messages if not provided
  true "${STDLOG_DEFAULT_LEVEL:=5}" # Notice
  # Colorize terminal output
  #true "${STDLOG_UC_ANSI:=1}"
}

stdlog_uc_lib__init ()
{
  true
}


stdlog_init () # ~ HANDLER-NAME LOGGER [FILTERS...]
{
  argv_uc__argc_n :stdlog-init $# ge 2 || return
  local name="$1" logger="$2" filters
  shift 2
  while test $# -gt 0
  do
    case "$1" in
      ( severity )
        filters="${filters:-}${filters:+" | "}syslog_logger_stderr_filter"
        ;;
      ( colorize )
        filters="${filters:-}${filters:+" | "}syslog_logger_colorize_filter"
        ;;
      ( * ) ${LOG:?} error :stdlog-init "No such filter" "$1" ; return 1 ;;
    esac
    shift
  done

# XXX: filtering stderr is problematic, weird stuff may happen.
# Besides filtering events before they happen is just as useful, but I
# like the idea to either colorize or maybe post-process the log lines as
# well.

# TODO: output_diagnostics filter is a simple stdout ANSII fancifier
# it can '#' prefix and make text grey. I wonder if it can track filepaths as
# well, output all diagnostics in blocks per file.
# And/Or track source nesting.
# maybe using some kind of directives, put on stdout in pipe-mode.
# or just dump it at the end of boot

  eval "$(cat <<EOM
$name () # ~ [Line-Type] [Header] Msg [Ctx] [Exit]
{
  local r
  {
    # Filtering stderr from stdlog_to_syslog means it cannot detect tty at
    # stderr, so we need to do it here
    # XXX: for now just turn quiet non-tty stderr off
    : "\${UC_QUIET:=0}"
    slog=$logger stdlog_to_syslog "\$@"

    } $(test -z "${filters-}" ||
      echo "2>&1 | $filters 1>&2 ")

  test -z "\${r-}" || return \$r
  # XXX: test \${STDLOG_UC_EXITS:-1} -eq 0 -o -z "\${5-}" || exit \$5
  return \${5:-0}
}
EOM
      )"

  # FIXME: && ${INIT_LOG:?} info ":uc:stdlog" "Initialized" "$name filters: $filters"
}

log_src_id_var()
{
  test -n "${log_key-}" || {
    test -n "${stderr_log_channel-}" && {
      log_key="$stderr_log_channel"
    } || {
      test -n "${base-}" || {
        base="\${scriptname:?}[\$\$]"
        #test -n "$scriptname" || {
        #  scriptpathname="$(realpath -- "$0")"
        #  scriptname=$(basename -- "$scriptname")
        #}
      }
      test -n "$base" && {
        test -n "${scriptext-}" || scriptext=.sh
        log_key=$base\$scriptext
      } || echo "Cannot get var-log-key" 1>&2;
    }
  }
}

log_src_id()
{
  eval echo \"$log_key\"
}

log()
{
  test -n "${log_key-}" || log_src_id_var
  printf -- "[$(log_src_id)] $1\n"
}

stderr_log_inner ()
{
  case "$(echo $1 | tr 'A-Z' 'a-z')" in
    warn*|err*|notice ) log "$1: $2" 1>&2 ;;
    * ) log "$2" 1>&2 ;;
  esac
}

stdlog_v ()
{
  : "${v:=${verbosity:-${STDLOG_UC_LEVEL:?}}}"
}

# XXX: simple handler for early during script sourcing, with INIT_LOG.
# TODO: should INIT_LOG callers should use status int to indicate level, not header.
# or just use the mappings from syslog-uc lib
stderr_log () # ~ <...:ll>
{
  stdlog_v && test $v -lt ${5:-${STDLOG_DEFAULT_LEVEL:?}} && return
  [[ $2 =~ ^: ]] && set -- "$1" "${UC_LOG_BASE:-}$2" "$3" "${4:-}"
  log_key=$2 stderr_log_inner "$1" "$3 <$4>"
}

# std-v <level>
# if verbosity is defined, return non-zero if <level> is below verbosity treshold
std_v ()
{
  test -z "${verbosity:-}" || test ${verbosity:?} -ge ${1:?}
}

# same as std-V but also override verbosity from 'v' if set
std_V ()
{
  test -z "${v-}" || verbosity=$v; std_v "$@"
}

std_exit () # [exit-at-level]
{
  test -n "${1-}" || return 0
  true ${std_exit:=exit}
  $std_exit $1
}

emerg()
{
  test $# -le 2 || return 64
  std_v 0 && stderr_log_inner "Emerg" "$1"
  std_exit ${2-}
}
std_alert()
{
  test $# -le 2 || return 64
  std_v 1 && stderr_log_inner "Alert" "$1"
  std_exit ${2-}
}
crit()
{
  test $# -le 2 || return 64
  std_v 2 && stderr_log_inner "Crit" "$1"
  std_exit ${2-}
}
error()
{
  test $# -le 2 || return 64
  std_v 3 && stderr_log_inner "Error" "$1"
  std_exit ${2-}
}
warn()
{
  test $# -le 2 || return 64
  std_v 4 && stderr_log_inner "Warning" "$1"
  std_exit ${2-}
}
note()
{
  test $# -le 2 || return 64
  std_v 5 && stderr_log_inner "Notice" "$1"
  std_exit ${2-}
}
notice() { note "$@"; }
std_info()
{
  test $# -le 2 || return 64
  std_v 6 && stderr_log_inner "Info" "$1"
  std_exit ${2-}
}
debug()
{
  test $# -le 2 || return 64
  std_v 7 && stderr_log_inner "Debug" "$1"
  std_exit ${2-}
}

stdlog_to_syslog () # {slog,r} ~ [Line-Type] [Header] Msg [Ctx] [Exit]
{
  local lt
  lt="$1" || return 64
  test -n "$lt" || lt=notice

  test -z "${4-}" && {
    $slog "$lt" "${3-}" "" ${2-} || r=$?
  } || {
    $slog "$lt" "$3 <$4>" "" ${2-} || r=$?
  }
}

# XXX: filter on syslog tail output
stdlog_uc__syslog_colorize ()
{
  local b=${BOLD-} n=${NORMAL-} B=${BLACK-} y=${YELLOW-} w=${WHITE-} \
    g=${GREEN-} l=${BLUE-} r=${RED-}

  # I use bold-black a lot with terminal 'show bold lighter' option on.
  local bb=${b}${B}

  sed 's/^<\([0-9]*\)>/\1 /g' | while read PRI rest
  do
    fnmatch "[0-9]*" "$PRI" || {

      # All non-logger lines are yellow
      echo "${n}${y}$PRI $rest${n}"
      continue
    }

    # Get facility level and severity level
    flvl=$( echo "$PRI / 8" | bc)
    slvl=$( echo "$PRI % 8" | bc)

    # Optionally display name-codes besides numral facility.severity levels
    test "${stdlog_uc__syslog_colorize__resolve_num:-0}" = 1 && {
      fname=$(syslog_facility_name "$flvl"|| echo "(unknown)")
      sname=$(syslog_level_name "$slvl"|| echo "(unknown)")

      printf "$bb%2s\%1i.${n}" "$fname" "$flvl"
    } || {
      printf "$bb%i.${n}" "$flvl"
    }

    # Assign detail color for log-line based on severity-level
    local slvlc
    case "$slvl" in
      0 ) slvlc="${b}${w}$BG_${r}" ;; # emerg
      1 ) slvlc="${b}${r}" ;; # alert
      2 ) slvlc="${b}${y}" ;; # crit
      3 ) slvlc="${r}" ;; # error
      4 ) slvlc="${y}" ;; # warn
      5 ) slvlc="${l}" ;; # notice
      6 ) slvlc="${g}" ;; # info
      7 ) slvlc="${b}${B}" ;; # debug
    esac

    # Optionally display name-codes besides numral facility.severity levels
    test "${stdlog_uc__syslog_colorize__resolve_num:-0}" = 1 && {
      printf "$slvlc%s\%i$bb" "$sname" "$slvl"
    } || {
      printf "$slvlc%i$bb" "$slvl"
    }
    printf "$bb<${n}$slvlc$PRI$bb>"

    # Color rest of logger line, including our stdlog '<context>' part
    # <date-time dark> <sylog-tag default/normal> <message bold> '<'<context green>'>'
    printf "$rest\n" | sed -E '
s/\<E[0-9]+\>/'${y}'&'${g}'/g
s/^([^ ]+ [0-9]+ [0-9:]+) ([A-Za-z_])/\1 '${n}'\2/g
s/: ([^<]*)/'$bb': '${n}${b}'\1'${n}'/g
s/: ([^<]*)</'$bb': '${n}${b}'\1'$bb'</g
s/<([^>]*)>/<'${n}${g}'\1'$bb'>'${n}'/g
    '

# Coloring other separators just doesn't work well
#s/(:|\[[0-9]+\])/'$bb'\1'${n}'/g

  done
}

# Rewrite <PRI> prefix of syslog output lines to something almost identical.
#
# XXX: Enables level-threshold filter on syslog tail output
syslog_logger_stderr_filter ()
{
  sed 's/^<\([0-9]*\)>/\1 /g' | while read PRI rest
  do
    # XXX: cleanup
    { test -n "$PRI" && fnmatch "[0-9]*" "$PRI"
    } || {
      echo "$PRI $rest"
      continue
    }

    # Get facility level and severity level
    flvl=$( echo "$PRI / 8" | bc )
    slvl=$( echo "$PRI % 8" | bc )

    # XXX: ?
    test $slvl -le $STDLOG_UC_LEVEL || continue

    echo "<$PRI>$rest"
  done
}

syslog_logger_colorize_filter ()
{
  test "${STDLOG_UC_ANSI:-1}" = "1" && stdlog_uc__syslog_colorize || cat
}

#
