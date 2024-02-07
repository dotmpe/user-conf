#!/usr/bin/env bash

## args:


# Simple helper to check for no or greater-/less-than argc
args_uc__argc () # ~ evttag argc test expectedc
{
  local tag="${1:-":(args)"}" test="${3:-"eq"}" expc="${4:-0}"
  test ${2:--1} -$test $expc || {
    ${uc_log:-$LOG} error "$tag" "Expected argument count $test $expc, got ${2:--1}"
    return $_E_GAE
  }
}

# Idem as args_uc__argc but also check every argument value is non-empty
args_uc__argc_n ()
{
  args_uc__argc "$@" || return
  local arg
  for arg in "$@"
  do
    test -n "$arg" && continue
    ${uc_log:-$LOG} error "${1:-":(args-n)"}" "Got empty argument"
    return 63
  done
}


args_has_next () # ~ <Argv...> # True if more for current sequence is available.
{
  test $# -gt 0 -a "${1-}" != "--"
}

args_has_none () # ~ <Argv...> # True if args is empty or before start of next sequence.
{
  test $# -eq 0 -o "${1-}" = "--"
}

args_is_seq () # ~ <Argv...> # True if immediate item is '--' continuation.
{
  test "${1-}" = "--"
}

args_trail_seq ()
{
  test $# -gt 0 && args_is_seq "$@"
}

# Read arguments until --, accumulate more_args and track more_argc.
# For convenience, this processes a leading '--' arg as well. So in that case
# instead of reading an empty or end-of sequence it reads the next.
# Returns false if no args where handled.
#
# Typical usage is 'args_more "$@" && shift $more_argc' and then handle
# $more_args contents.
#
# NOTE: use args_q to set quoting
args_more () # ~ <Argv...> # Read until '--', and set $more_arg{c,v}
{
  test $# -gt 0 || return
  more_argc=$#
  # Don't require this but read leading '--' anyway
  args_is_seq "$1" && shift

  test $# -eq 0 || {
    # Found empty sequence?
    args_is_seq "$1" && { more_args=; more_argc=1; return; }

    # Get all args
    test ${args_q:-1} -eq 1 && more_args="${1@Q}" || more_args="$1"
    first=true
    while $first || args_has_next "$@"
    do
      shift
      first=false
      test $# -gt 0 || break
      args_is_seq "$1" || {
          test ${args_q:-1} -eq 1 &&
              more_args="$more_args ${1@Q}" ||
              more_args="$more_args ${1}"
      }
    done
  }
  more_argc=$(( more_argc - $# ))
}

#
