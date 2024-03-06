uc_sys_lib__load()
{
  lib_require envd
}

uc_sys_lib__init ()
{
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


sys_debug () # ~ [<...>]
{
  # TODO:
  echo false
}
# copy: sys.lib/sys-debug

# A helper for inside ${var?...} expressions
sys_exc () # Format exception-id and message
{
  ! "${DEBUG:-$(sys_debug exceptions)}" && echo "$1: $2" || sys_exc_trc "$1: $2"
}
# copy: sys.lib/sys-exc

# system-exception-trace: Helper to format callers list including custom head.
sys_exc_trc () # ~ [<Head>] ...
{
  echo "${1:-Trace:}"
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
sys_stat ()
{
  local stat=$?
  while [[ $# -gt 0 ]]
  do
    test $stat "$1" "$2" || return $stat
    shift 2
  done
}
