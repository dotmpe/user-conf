#!/usr/bin/env bash

## stdargv

# At some point I found out Bash allows all kinds of compound variables for
# sommand invocations, including variable prefixes. It only stops at pipes,
# and true && ... || false constructs. Forgot what to call them atm.

# But I should exploit this and argv handling is still bugging me.
# I would want to use more real optparse capabilities. But not always.
# And also this handling is part of the question how to treat errors in shell scripts.

# I want an idiomatic and generic approach to this.

# <testargs> || {
#       <parse and amend argv, or set defaults>
#       set -- ...
# } || return <irrecoverable status>

stdargv_lib__load ()
{
  true
}

stdargv_lib__init ()
{
  if `getopt -T >/dev/null 2>&1` ; [ $? = 4 ] ; then
    $LOG "info" ":std:argv:lib-init" "Found enhanced getopt(1)"
    STDARGV_GETOPT=1
  else
    $LOG "warn" ":std:argv:lib-init" "No option parsing (old getopt(1))"
    STDARGV_GETOPT=0
  fi
}

## A real simple argv checker
# XXX: somehow use getopt if available as well, let std:argv switch modes maybe
# like std:fail
std_argv () # [ test exp cnt ] -- [ argv-tests...]
{
  argv_is_seq "$1" || {
    local test=ge
    argv_more "$@" || return
    test $more_argc -ge 3 && { test=$1; shift; more_argc=$(( $more_argc - 1 )); }
    assert $test $1 $2 "" "${3:-"Expected argument-count"}" || return $_E_US_AE
    shift $more_argc
    test $# -gt 0 || return
  }

  while argv_more "$@" && shift $more_argc
  do
    $more_argv || return
  done
}

std_argv_min () # [ exp cnt ] -- [ argv-tests...]
{
  std_argv ge "$@"
}

# Id: user-conf/0.2.0 script/stdargv-uc.lib.sh
