#!/bin/sh

set -e

# No-Op(eration)
noop()
{
  . /dev/null # source empty file
  #echo -n # echo nothing
  #set -- # clear arguments (XXX set nothing?)
}

func_exists()
{
  type $1 2> /dev/null 1> /dev/null || return $?
  return 0
}

try_exec_func()
{
  test -n "$1" || return 97
  func_exists $1 || return $?
  local func=$1
  shift 1
  $func "$@" || return $?
}

