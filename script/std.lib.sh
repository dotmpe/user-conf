#!/bin/sh


var_log_key()
{
  test -n "$log_key" || {
    test -n "$log" && {
      log_key="$log"
    } || {
      test -n "$base" && {
        log_key=$base.sh
      }
    }
  }
}

# stdio helper functions
log()
{
  var_log_key
  printf -- "[$log_key] $1\n"
  unset log_key
}

err()
{
  log "$1" 1>&2
  test -z "$2" || exit $2
}

stderr()
{
  case "$(echo $1 | tr 'A-Z' 'a-z')" in
    warn*|err*|notice ) err "$1: $2" "$3" ;;
    * ) err "$2" "$3" ;;
  esac
}

std_v()
{
  test -z "$verbosity" && return || {
    test $verbosity -ge $1 && return || return 1
  }
}

std_exit()
{
  test "$1" != "0" -a -z "$1" && return 1 || exit $1
}

#emerg() 1
#crit() 2
crit()
{
  std_v 3 || std_exit $2 || return 0
  stderr "Crit" "$1" $2
}
error()
{
  std_v 3 || std_exit $2 || return 0
  stderr "Error" "$1" $2
}
warn()
{
  std_v 4 || std_exit $2 || return 0
  stderr "Warning" "$1" $2
}
note()
{
  std_v 5 || std_exit $2 || return 0
  stderr "Notice" "$1" $2
}
info()
{
  std_v 6 || std_exit $2 || return 0
  stderr "Info" "$1" $2
}
debug()
{
  std_v 7 || std_exit $2 || return 0
  stderr "Debug" "$1" $2
}


