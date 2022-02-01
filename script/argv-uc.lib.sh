#!/bin/sh

## argv:


# Simple helper to check for no or greater-/less-than argc
argv_uc__argc () # ~ evttag argc test expectedc
{
  local tag="${1:-":(args)"}" test="${3:-"eq"}" expc="${4:-0}"
  test ${2:--1} -$test $expc || {
    ${uc_log:-$LOG} error "$tag" "Expected argument count $test $expc, got ${2:--1}"
    return $_E_GAE
  }
}

# Idem as argv_uc__argc but also check every argument value is non-empty
argv_uc__argc_n ()
{
  argv_uc__argc "$@" || return
  local arg
  for arg in $@; do
    test -n "$arg" && continue
    ${uc_log:-$LOG} error "${1:-":(args-n)"}" "Got empty argument"
    return 63
  done
}


argv_has_next ()
{
  test $# -gt 0 -a "${1-}" != "--"
}

argv_has_none ()
{
  test $# -eq 0 -o "${1-}" = "--"
}

argv_is_seq ()
{
  test "${1-}" = "--"
}

# Read arguments until --, set more_argv to that list and more_argc
# eventually to the amount consumed (counts all args, one leading and trailing '--' as well)
# XXX: does not accept spaces in args
argv_more ()
{
  test $# -gt 0 || return
  more_argc=$#
  # Don't require this but read leading '--' anyway
  argv_is_seq "$1" && shift

  test $# -gt 0 || return 1

  # Found empty sequence?
  argv_is_seq "$1" && { more_argv=; more_argc=1; return; }

  # Get all args
  more_argv="$1"
  test $# -eq 1 || {
    first=true
    while $first || argv_has_next "$@"
    do
      shift
      first=false
      test $# -gt 0 || break
      argv_is_seq "$1" || more_argv="$more_argv ${1@Q}"
    done
  }
  more_argc=$(( $more_argc - $# ))
}

#
