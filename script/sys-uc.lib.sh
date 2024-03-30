#!/usr/bin/env bash

## Sys: dealing with vars, functions, env.

sys_uc_lib__load ()
{
  lib_require os || return

  : "${LOG:?"No LOG env"}"
  if_ok "${uname:=$(uname -s)}" &&
  if_ok "${HOST:=$(hostname -s)}" || return
  : "${hostname:=${HOST,,}}"
}

uc_fun "${func_exists:-func_exists}" || {
  eval "$_ () { uc_fun \"\$@\"; }"
}

# Error unless non-empty and true-ish
trueish () # Str
{
  test $# -eq 1 -a -n "${1-}" || return
  case "$1" in
    [Oo]n|[Tt]rue|[Yyj]|[Yy]es|1)
      return 0;;
    * )
      return 1;;
  esac
}

uc_fun append_path ||
append_path ()
{
  add_env_path "" "${1:?}"
}

uc_fun prepend_path ||
prepend_path ()
{
  add_env_path "${1:?}"
}

add_env_path() # <Prepend-Value> <Append-Value>
{
  test $# -ge 1 -a -n "$1" -o -n "${2:-}" || return 64
  test -e "$1" -o -e "${2-}" || {
    echo "add_env_path: No such file or directory '$*'" >&2
    return 1
  }
  test -n "${1:-}" && {
    case "$PATH" in
      $1:* | *:$1 | *:$1:* ) ;;
      * ) eval PATH=$1:$PATH ;;
    esac
  } || {
    test -n "${2:?}" && {
      case "$PATH" in
        $2:* | *:$2 | *:$2:* ) ;;
        * ) eval PATH=$PATH:$2 ;;
      esac
    }
  }
  # XXX: to export or not to launchctl
  #test "$uname" != "Darwin" || {
  #  launchctl setenv "$1" "$(eval echo "\$$1")" ||
  #    echo "Darwin setenv '$1' failed ($?)" >&2
  #}
}

#uc_fun append_path_lookup ||
append_path_lookup ()
{
  add_env_path_lookup "${1:?}" "" "${2:?}"
}

# Add an entry to colon-separated paths, ie. PATH, CLASSPATH alike lookup paths
add_env_path_lookup() # Var-Name Prepend-Value Append-Value
{
  test $# -ge 2 -a $# -le 3 || return 64
  local val="$(eval echo "\${$1-}")"
  test -e "$2" -o -e "${3-}" || {
    echo "No such file or directory '$*'" >&2
    return 1
  }
  test -n "$2" && {
    case "$val" in
      $2:* | *:$2 | *:$2:* ) ;;
      * ) test -n "$val" && eval $1=$2:$val || eval $1=$2;;
    esac
  } || {
    test -n "$3" && {
      case "$val" in
        $3:* | *:$3 | *:$3:* ) ;;
        * ) test -n "$val" && eval $1=$val:$3 || eval $1=$3;;
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

# Source profile if it exists, or create one using given default and current env
# The result should be whatever is defined in an existing profile, the current env and whatever
# defaults where provided. If the file exists, the processing costs should be minimal, and mostly
# determined by the profile file.
# This means the env var validation is left to the profile script, and the profile script is only
# written if a value for every var is provided. No other schema validation.
req_profile() # Name Vars...
{
  test -n "$SCR_ETC" -a -w "$SCR_ETC" || error "Scr-Etc '$SCR_ETC'" 1
  local name=$1 ; shift

  test -e "$SCR_ETC/${name}.sh" && {
    # NOTE: only simply scalars, no quoting, whitespace etc.
    eval $* ||
        error "Error evaluating defaults '$*'" 1
    . "$SCR_ETC/${name}.sh" ||
        error "Error sourcing '${name}' profile" 1
  } || {
    {
      while test $# -gt 0
      do
          fnmatch *"="* "$1" && {
            var=$(echo "$1" | cut -f 1 -d '=')
            value=$(echo "$1" | sed 's/^[^=]*=//g')
          } || {
            var=$1
            value="$(eval echo \"\$$var\")"
          }
          test -n "$value" || stderr error "Missing '$var' value" 1
          printf -- "$var=\"$value\"\n"
          shift
      done
    } > "$SCR_ETC/${name}-temp.sh"
    mv "$SCR_ETC/${name}-temp.sh" "$SCR_ETC/$name.sh"
  }
}

sys_debug ()
{
  test $# -gt 0 || set -- debug
  while test $# -gt 0
  do
    # Default to doing IF-OR
    case "$1" in [A-Za-z]* ) set -- "?$1" "${@:2}"; esac

    # Check IF ON/OFF condition
    case "$1" in
      "?"* ) sys_debug_mode "${1:1}" ;;
      "!"* ) sys_not sys_debug_mode "${1:1}" ;;
    esac ||
      return

    # XXX: Check SET ON/OFF mode
    case "$1" in [+-]* )
    esac

    shift
  done
}

sys_debug_mode ()
{
  local lk=${lk-}:us:sys.lib:debug-mode
  case "$1" in
    ( assert ) "${ASSERT:-${DIAG:-${DEBUG:-${DEV:-false}}}}" ;;
    ( debug ) "${DEBUG:-${DEV:-false}}" ;;
    ( dev ) "${DEV:-false}" ;;
    ( diag ) "${DIAG:-${INIT:-${DEBUG:-false}}}" ;;
    ( exceptions ) "${VERBOSE:-false}" || "${DIAG:-true}" || ! "${QUIET:-false}" ;;
    ( init ) "${INIT:-false}" ;;
    ( verbose ) "${VERBOSE:-false}" ;;

    ( * ) $LOG alert "$lk" "No such mode" "$1" ${_E_script:?"$(sys_exc "$lk")"}
  esac
}

# XXX: hook to test for envd/uc and defer, returning cur bool value for setting
sys_debug_ () # ~ [<...>]
{
  sys_debug "$@" && echo true || echo false
}

# A helper for inside ${var?...} expressions
sys_exc () # ~ <Head>: <Label> # Format exception-id and message
{
  ! "${DEBUG:-$(sys_debug_ exceptions)}" && echo "$1: ${2-Expected}" ||
    # TODO: use localenv for params
    "${sys_on_exc:-sys_exc_trc}" "$1" "${2-Expected}" 3 "${@:3}"
}

# system-exception-trace: Helper to format callers list including custom head.
sys_exc_trc () # ~ [<Head>] [<Msg>] [<Offset=2>] ...
{
  echo "${1:-us:sys: E$? source trace:}${2+ }${2}"
  std_findent "  - " sys_callers "${3-2}"
}

# Test for fail/false status exactly, or return status. Ie. do not mask all
# non-zero statusses, but one specifically. See also sys-astat.
sys_not ()
{
  "$@"
  [[ $? -eq ${_E_fail:-1} ]]
}


