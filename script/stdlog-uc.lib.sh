#!/bin/sh

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


stdlog_uc_lib_load ()
{
  true "${STDLOG_UC_LEVEL:=6}"
  true "${STDLOG_UC_EXITS:=3}"
  #true "${STDLOG_UC_ANSI:=0}"
}

stdlog_uc_lib_init () { true; }


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
      ( * ) $LOG error :stdlog-init "No such filter" "$1" ; return 1 ;;
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
  # test \${STDLOG_UC_EXITS:-1} -eq 0 -o -z "\${5-}" || exit \$5
}
EOM
      )"
}

log_src_id_var()
{
  test -n "${log_key-}" || {
    test -n "${stderr_log_channel-}" && {
      log_key="$stderr_log_channel"
    } || {
      test -n "${base-}" || {
        base="\$scriptname[\$\$]"
        test -n "${scriptname-}" || {
          scriptpathname="$(realpath -- "$0")"
          scriptname=$(basename -- "$scriptname")
        }
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
notice() { note "$@"; }
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
  # XXX: These may take a bit more to all to be set as shell/term/prompt has not
  # been sourced
  # See sh-ansi-tpl-uc.lib

  : "${BLACK:="$(tput setaf 0)"}"
  : "${RED:="$(tput setaf 1)"}"
  : "${GREEN:="$(tput setaf 2)"}"
  : "${YELLOW:="$(tput setaf 3)"}"
  : "${BLUE:="$(tput setaf 4)"}"
  : "${CYAN:="$(tput setaf 5)"}"
  : "${MAGENTA:="$(tput setaf 6)"}"
  : "${WHITE:="$(tput setaf 7)"}"

  : "${BG_BLACK:="$(tput setab 0)"}"
  : "${BG_RED:="$(tput setab 1)"}"
  : "${BG_GREEN:="$(tput setab 2)"}"
  : "${BG_YELLOW:="$(tput setab 3)"}"
  : "${BG_BLUE:="$(tput setab 4)"}"
  : "${BG_CYAN:="$(tput setab 5)"}"
  : "${BG_MAGENTA:="$(tput setab 6)"}"
  : "${BG_WHITE:="$(tput setab 7)"}"

  : "${REVERSE:=}"
  : "${BOLD:="$(tput bold)"}"
  : "${NORMAL:="$(tput sgr0)"}"

  # XXX: I use bold-black a lot
  local bb=$BOLD$BLACK

  sed 's/^<\([0-9]*\)>/\1 /g' | while read PRI rest
  do
    fnmatch "[0-9]*" "$PRI" || {

      # All non-logger lines are yellow
      echo "$NORMAL$YELLOW$PRI $rest$NORMAL"
      continue
    }

    # Get facility level and severity level
    flvl=$( echo "$PRI / 8" | bc)
    slvl=$( echo "$PRI % 8" | bc)

    # Optionally display name-codes besides numral facility.severity levels
    test "${stdlog_uc__syslog_colorize__resolve_num:-0}" = 1 && {
      fname=$(syslog_facility_name "$flvl"|| echo "(unknown)")
      sname=$(syslog_level_name "$slvl"|| echo "(unknown)")

      printf "$bb%2s\%1i.$NORMAL" "$fname" "$flvl"
    } || {
      printf "$bb%i.$NORMAL" "$flvl"
    }

    # Assign detail color for log-line based on severity-level
    local slvlc
    case "$slvl" in
      0 ) slvlc="$BOLD$WHITE$BG_RED" ;; # emerg
      1 ) slvlc="$BOLD$RED" ;; # alert
      2 ) slvlc="$BOLD$YELLOW" ;; # crit
      3 ) slvlc="$RED" ;; # error
      4 ) slvlc="$YELLOW" ;; # warn
      5 ) slvlc="$BLUE" ;; # notice
      6 ) slvlc="$GREEN" ;; # info
      7 ) slvlc="$BOLD$BLACK" ;; # debug
    esac

    # Optionally display name-codes besides numral facility.severity levels
    test "${stdlog_uc__syslog_colorize__resolve_num:-0}" = 1 && {
      printf "$slvlc%s\%i$bb" "$sname" "$slvl"
    } || {
      printf "$slvlc%i$bb" "$slvl"
    }
    printf "$bb<$NORMAL$slvlc$PRI$bb>"

    # Color rest of logger line, including our stdlog '<context>' part
    # <date-time dark> <sylog-tag default/normal> <message bold> '<'<context green>'>'
    printf "$rest\n" | sed -E '
s/\<E[0-9]+\>/'$YELLOW'&'$GREEN'/g
s/^([^ ]+ [0-9]+ [0-9:]+) ([A-Za-z_])/\1 '$NORMAL'\2/g
s/: ([^<]*)/'$bb': '$NORMAL$BOLD'\1'$NORMAL'/g
s/: ([^<]*)</'$bb': '$NORMAL$BOLD'\1'$bb'</g
s/<([^>]*)>/<'$NORMAL$GREEN'\1'$bb'>'$NORMAL'/g
    '

# Coloring other separators just doesn't work well
#s/(:|\[[0-9]+\])/'$bb'\1'$NORMAL'/g

  done
}

# XXX: Enable level-threshold filter on syslog tail output
syslog_logger_stderr_filter ()
{
  sed 's/^<\([0-9]*\)>/\1 /g' | while read PRI rest
  do
    { test -n "$PRI" && fnmatch "[0-9]*" "$PRI"
    } || {
      echo "$PRI $rest"
      continue
    }

    # Get facility level and severity level
    flvl=$( echo "$PRI / 8" | bc )
    slvl=$( echo "$PRI % 8" | bc )

    test $slvl -le $STDLOG_UC_LEVEL || continue

    echo "<$PRI>$rest"
  done
}

syslog_logger_colorize_filter ()
{
  test "${STDLOG_UC_ANSI:-1}" = "1" && stdlog_uc__syslog_colorize || cat
}

#
