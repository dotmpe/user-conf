#!/bin/sh

### U-c syslog lib

## Syslog events and/or priority-prefixed log lines on stderr

# Generates output on stderr as appropiate, and log severe events to syslog.
# Sensible defaults depend heavily on context.
# Without explicit configuration, output is disabled as long as the stderr is not at terminal, and in an interactive terminal.

# For syslog logger output colorization, see stdlib-uc.lib


#
syslog_uc_lib_load ()
{
  # XXX: These will need to be defaulted based on context. For system profile or
  # RC's and even user files they would be more conservative at first...

  # Uc-Log-Base is the tag name or tag prefix passed to logger, the default
  # value for the tag field, or with which ':'-prefixed headers are concatenated
  # if the caller provides them.
  true "${UC_LOG_BASE:="${scriptname:-"$USER syslog-uc[$$]"}"}"

  true "${UC_LOG_LEVEL:=5}" # stderr: Notices and above
  # Only print to stderr based on the events severity level.
  # This is independent of syslog event.

  # UC_{LOG_BASE,SYSLOG_{LEVEL,OFF},QUIET}
  true "${UC_SYSLOG_LEVEL:=3}" # syslog: Errors and above
  # Only send an actual syslog event based on the severity level.
  # With either UC_SYSLOG_LEVEL=-1 or UC_SYSLOG_OFF=1 the logger can be put in
  # 'no-act' mode to prevent actual syslog events.

  # UC_SYSLOG_OFF=0 # Default value
  # Turns off any syslog events, only log according to stderr according to its
  # settings. This silently overrides any UC_SYSLOG_LEVEL setting.

  # UC_QUIET=1 # Default value
  # UC_QUIET is standard on and disables stderr output unless stderr is at a
  # terminal/interactive TTY. With UC_QUIET=0 off it will output regardless.

  # In every cases chatter on stderr still subject to UC_LOG_LEVEL, so to
  # completely shut up stderr UC_LOG_LEVEL=-1 has that effect.

  # XXX: this could be off at 'dumb' and non-interactive by default
  # not sure when/if to toggle this yet.
  test -n "${UC_PROFILE_LOG_FILTERS-}" || : "${UC_PROFILE_LOG_FILTERS:"severity colorize"}"
}

syslog_uc_lib_init () # ~
{
  true
}

# Init generates a new stdlog frontend for uc_syslog_1, the syslog 'logger'
# wrapper function that obeys the parameters from syslog-uc.lib-load

# XXX: Colorize default, this sets it on. But need something in term-uc.lib
syslog_uc_init () # COLORIZE,UC_LOG_ANSI ~ [handle=syslog_uc_init]
{
  : "${UC_LOG_ANSI="${COLORIZE:-1}"}"
  stdlog_init ${1:-"syslog_uc_log"} uc_syslog_1 ${UC_PROFILE_LOG_FILTERS-}
}

# These mappings are take from LOGGER(1). See also
# <https://www.paessler.com/it-explained/syslog>

# Return level number as string for use with line-type or logger level, channel
# Basicly these correspond to KERN_<Level-Name> in the Linux kernel.
syslog_level_name() # Level-Num
{
  case "$1" in

      0 ) echo emerg ;;
      1 ) echo alert ;;
      2 ) echo crit ;;
      3 ) echo err ;;
      4 ) echo warn ;;
      5 ) echo notice ;;
      6 ) echo info ;;
      7 ) echo debug ;;

      * ) return 1 ;;
  esac
}

syslog_level_num() # Level-Name
{
  case "$1" in

      emerg )           echo 0 ;;
      alert )           echo 1 ;;
      crit  )           echo 2 ;;
      err   | error )   echo 3 ;;
      warn  | warning ) echo 4 ;;
      notice )          echo 5 ;;
      info  )           echo 6 ;;
      debug )           echo 7 ;;

      * ) return 1 ;;
  esac
}

# These are take from LOGGER(1) as well, but the mapping is less clear and does not seem to be complete in the manual.
syslog_facility_name()
{
  case "$1" in

      0 ) echo kern ;;
      1 ) echo user ;;
      2 ) echo mail ;;
      3 ) echo daemon ;;
      4 ) echo auth ;;
      5 ) echo syslog ;;
      6 ) echo lpr ;;
      9 ) echo cron ;;
      10 ) echo authpriv ;;
      11 ) echo ftp ;;
			# TODO: fill out completely, if ever needed...

      * ) return 1 ;;
  esac
}

syslog_facility_num()
{
  case "$1" in

      kern ) echo 0 ;;
      user ) echo 1 ;;
      mail ) echo 2 ;;
      daemon ) echo 3 ;;
      auth | security ) echo 4 ;;
      syslog ) echo 5 ;;
      lpr ) echo 6 ;;
      news ) echo 7 ;;
      uucp ) echo 8 ;;
      cron ) echo 9 ;;
      authpriv ) echo 10 ;; # XXX: or the other way around with 4
      ftp ) echo 11 ;;
      #ntp ) echo 12 ;; # 12-15 is not in LOGGER(1) or used on rsyslog?

      local0 ) echo 16 ;;
      local1 ) echo 17 ;;
      local2 ) echo 18 ;;
      local3 ) echo 19 ;;
      local4 ) echo 20 ;;
      local5 ) echo 21 ;;
      local6 ) echo 22 ;;
      local7 ) echo 23 ;;

      * ) return 1 ;;
  esac
}

# Basic syslog logger wrapper function.
# Default priority (facility/level) is user.notice (1.5 or PRI 13).
# For default tag(s) see UC_LOG_BASE. Multiple tags a are joined with ':'.
uc_syslog_1 () # UC_{LOG_BASE,SYSLOG_{LEVEL,OFF},QUIET} ~ [lvl=notice] msg [fac=user [tags]]
{
  test $# -ge 2 || return 64
  local lvl="$1" msg="$2"; shift 2
  test -n "$lvl" || lvl=notice
  local fac="${1-}"; shift
  test -n "$fac" || fac=user

  # First determine if we are going to generate a serial or syslog event at all
  local opts= lvlnum
  lvlnum=$(syslog_level_num $lvl) || {
    return $?
  }

  # ... and if so bail now
  { { test ${UC_LOG_LEVEL:-6} -ge $lvlnum &&
    test -t 2 -o "0" = "${UC_QUIET-1}"
  } || {
    test "0" = "${UC_SYSLOG_OFF:-0}" &&
    test ${UC_SYSLOG_LEVEL:-3} -ge $lvlnum
  }; } || return 0

  # Set tags. Prepend default tags if first argument ':'-prefixed.
  test $# -eq 0 && {
    set -- $UC_LOG_BASE || return
  } || { fnmatch ":*" "$1" && {
    local t1="$1"; shift
    set -- $UC_LOG_BASE "${t1:1}" "$@" || return; unset t1
  }; }

  # Chat on stdout as well if session is interactive (stderr is tty),
  # or if UC-Quiet mode is turned off (UC_QUIET=0).
  # But only at or above UC-Log-Level[=6].
  { test ${UC_LOG_LEVEL:-6} -ge $lvlnum &&
    test -t 2 -o "0" = "${UC_QUIET-1}"
  } && opts=-s

  # Turn off syslog if requested or below level
  {
    test "0" = "${UC_SYSLOG_OFF:-0}" &&
    test ${UC_SYSLOG_LEVEL:-3} -ge $lvlnum
  } || {
    opts="$opts --no-act"
  }

  # Silence error if logger has been turned off delibarately
  test -s /etc/log || opts="$opts --socket-errors=off"

  local tags="$(printf '%s:' "$@")"
  logger $opts -t "${tags:0:-1}" -p "$fac.$lvl" "$msg"
}

#
