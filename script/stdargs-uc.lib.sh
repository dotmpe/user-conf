#!/usr/bin/env bash

## stdargs

# At some point I found out Bash allows all kinds of compound variables for
# sommand invocations, including variable prefixes. It only stops at pipes,
# and true && ... || false constructs. Forgot what to call them atm.

# But I should exploit this and args handling is still bugging me.
# I would want to use more real optparse capabilities. But not always.
# And also this handling is part of the question how to treat errors in shell scripts.

# I want an idiomatic and generic approach to this.

# <testargs> || {
#       <parse and amend args, or set defaults>
#       set -- ...
# } || return <irrecoverable status>

stdargs_lib__load ()
{
  true
}

stdargs_lib__init ()
{
  if `getopt -T >/dev/null 2>&1` ; [ $? = 4 ] ; then
    $LOG "info" ":std:args:lib-init" "Found enhanced getopt(1)"
    STDARGV_GETOPT=1
  else
    $LOG "warn" ":std:args:lib-init" "No option parsing (old getopt(1))"
    STDARGV_GETOPT=0
  fi
}

## A real simple args checker
# XXX: somehow use getopt if available as well, let std:args switch modes maybe
# like std:fail
std_args () # [ test exp cnt ] -- [ args-tests...]
{
  args_is_seq "$1" || {
    local test=ge
    args_more "$@" || return
    test $more_argc -ge 3 && { test=$1; shift; more_argc=$(( $more_argc - 1 )); }
    assert $test $1 $2 "" "${3:-"Expected argument-count"}" || return $_E_US_AE
    shift $more_argc
    test $# -gt 0 || return
  }

  while args_more "$@" && shift $more_argc
  do
    $more_args || return
  done
}

std_args_min () # [ exp cnt ] -- [ args-tests...]
{
  std_args ge "$@"
}

# Id: user-conf/0.2.0 script/stdargs-uc.lib.sh
