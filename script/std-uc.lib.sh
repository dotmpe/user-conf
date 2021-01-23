#!/bin/sh

## std: logging and dealing with the shell's stdio decriptors


std_uc_lib_load()
{
  true "${uname:="$(uname -s | tr '[:upper:]' '[:lower:]')"}"
  true "${choice_interactive:=$( test -t 0 && echo 1 || echo 0 )}"
  true "${verbosity:=4}"
}

std_uc_lib_init()
{
  test -x "$(which readlink)" || error "readlink util required for stdio-type" 1
  test -x "$(which file)" || error "file util required for stdio-type" 1
}

std_lib_check()
{
  std_iotype_check
}

std_iotype_check()
{
  case "$uname" in

    linux | cygwin_nt-* ) ;;
    darwin ) ;;

    * ) error "No stdio-type for $uname" ;;
  esac
  return 1
}

get_stdio_type() # IO-Num PId
{
  local io= pid=
  test -n "$1" && io=$1 || io=1
  case "$uname" in

    linux | cygwin_nt-* )
        test -n "${2-}" && pid=$2 || pid=$$
        test -e /proc/$pid/fd/${io} || error "No $uname FD $io"
        if readlink /proc/$pid/fd/$io | grep -q "^pipe:"; then
          export stdio_${io}_type=p
        elif file $( readlink /proc/$pid/fd/$io ) | grep -q 'character.special'; then
          export stdio_${io}_type=t
        else
          export stdio_${io}_type=f
        fi
      ;;

    darwin )

        test -e /dev/fd/${io} || error "No $uname FD $io"
        if file /dev/fd/$io | grep -q 'named.pipe'; then
          export stdio_${io}_type=p
        elif file /dev/fd/$io | grep -q 'character.special'; then
          export stdio_${io}_type=t
        else
          export stdio_${io}_type=f
        fi
      ;;

    "" ) error "Cannot determin stdio-type, no uname" ;;
    * ) error "No stdio-type for $uname" ;;
  esac
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
