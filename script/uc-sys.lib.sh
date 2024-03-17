uc_sys_lib__load()
{
  lib_require envd
}

uc_sys_lib__init ()
{
  throw ()  # Id Msg Ctx
  {
    local lk=${1:?}:sys.lib/throw ctx
    ctx="${3-}${3+:$'\n'}$(sys_exc "$1" "$2")"
    $LOG error "$lk" "${2-Exception}" "$ctx" ${_E_script:-2}
  }

  envd_dtype uc/sys.lib lib &&
  envd_fun source_all var_{assert,set}
}

source_all () # ~ <Sources...>
{
  while test $# -gt 0
  do . "${1:?}" || return
  done
}

# XXX: deprecate? rename?
sh_fun () # ~ <Name> ...
{
  declare -F "${1:?}" >/dev/null 2>&1
}

# TODO:
# -+  request mode change
# ?!  check for mode
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
      "!"* ) ! sys_debug_mode "${1:1}" ;;
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
  local lk=${lk-}:uc/sys.lib:debug-mode

  case "${1:1}" in
    ( assert ) "${ASSERT:-${DIAG:-${DEBUG:-${DEV:-false}}}}" ;;
    ( debug ) "${DEBUG:-${DEV:-false}}" ;;
    ( dev ) "${DEV:-false}" ;;
    ( diag ) "${DIAG:-${INIT:-${DEBUG:-false}}}" ;;
    ( exceptions ) "${VERBOSE:-false}" || "${DIAG:-true}" || ! "${QUIET:-false}" ;;
    ( init ) "${INIT:-false}" ;;
    # XXX: verbose: msg priv-lvl >= sess out-level
    ( verbose ) "${VERBOSE:-false}" ;;

    ( * ) $LOG alert "$lk" "No such mode" "$1" ${_E_script:?"$(sys_exc "$lk")"}
  esac
}

# XXX: hook to test for envd/uc and defer, returning cur bool value for setting
sys_debug_ () # ~ [<...>]
{
  sys_debug "$@" && echo true || echo false
}
# copy: sys.lib/sys-debug

# A helper for inside ${var?...} expressions
sys_exc () # Format exception-id and message
{
  ! "${DEBUG:-$(sys_debug_ exceptions)}" && echo "$1: $2" || sys_exc_trc "$1: $2"
}
# copy: sys.lib/sys-exc

# system-exception-trace: Helper to format callers list including custom head.
sys_exc_trc () # ~ [<Head>] ...
{
  echo "${1:-uc/sys: $? Source trace:}"
  for (( i=1; 1; i++ ))
  do
    if_ok "$(caller $i)" && echo "  - $_" || break
  done
}
# copy: sys.lib/sys-exc-trc

sys_assert () # ~ <Var-name> [<Value>] ...
{
  declare -n ref
  ref=${1:?"$(sys_exc sys:assert-var:ref@_1 "Variable name expected")"}
  ref="${ref-${2-}}"
}
# copy: sys.lib/sys-assert

sys_set () # ~ <Var-name> [<Value>] ...
{
  local var val=${2-} &&
  var=${1:?"$(sys_exc sys:set-var:var@_1 "Variable name expected")"} &&
  declare -n ref=$var &&
  ref=$val
}
# copy: sys.lib/sys-set

# XXX: new function: ignore last status if test succeeds, or return it
sys_astat ()
{
  local stat=$?
  while [[ $# -gt 0 ]]
  do
    test $stat "$1" "$2" || return $stat
    shift 2
  done
}
