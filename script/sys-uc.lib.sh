#!/usr/bin/env bash

## Sys: dealing with vars, functions, env.

sys_uc_lib_load()
{
  true "${uname:="$(uname -s | tr '[:upper:]' '[:lower:]')"}"
  true "${hostname:="$(hostname -s | tr 'A-Z' 'a-z')"}"
}

# Error unless non-empty and true-ish
trueish () # Str
{
  test -n "$1" || return 1
  case "$1" in
    [Oo]n|[Tt]rue|[Yyj]|[Yy]es|1)
      return 0;;
    * )
      return 1;;
  esac
}

add_env_path() # Prepend-Value Append-Value
{
  test -e "$1" -o -e "$2" || {
    echo "No such file or directory '$*'" >&2
    return 1
  }
  test -n "$1" && {
    case "$PATH" in
      $1:* | *:$1 | *:$1:* ) ;;
      * ) export PATH=$1:$PATH ;;
    esac
  } || {
    test -n "$2" && {
      case "$PATH" in
        $2:* | *:$2 | *:$2:* ) ;;
        * ) export PATH=$PATH:$2 ;;
      esac
    }
  }
  # XXX: to export or not to launchctl
  #test "$uname" != "Darwin" || {
  #  launchctl setenv "$1" "$(eval echo "\$$1")" ||
  #    echo "Darwin setenv '$1' failed ($?)" >&2
  #}
}

# Add an entry to colon-separated paths, ie. PATH, CLASSPATH alike lookup paths
add_env_path_lookup() # Var-Name Prepend-Value Append-Value
{
  local val="$(eval echo "\$$1")"
  test -e "$2" -o -e "$3" || {
    echo "No such file or directory '$*'" >&2
    return 1
  }
  test -n "$2" && {
    case "$val" in
      $2:* | *:$2 | *:$2:* ) ;;
      * ) test -n "$val" && export $1=$2:$val || export $1=$2;;
    esac
  } || {
    test -n "$3" && {
      case "$val" in
        $3:* | *:$3 | *:$3:* ) ;;
        * ) test -n "$val" && export $1=$val:$3 || export $1=$3;;
      esac
    }
  }
}

remove_env_path_lookup()
{
  local newval="$( eval echo \"\$$1\" | tr ':' '\n' | while read oneval
    do
      test "$2" = "$oneval" -o "$(realpath "$2")" = "$(realpath "$oneval")" &&
        continue ;
      echo "$oneval" ;
    done | tr '\n' ':' | strip_last_nchars 1 )"

  export $1="$newval"
}
