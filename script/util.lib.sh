#!/bin/sh


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

noop()
{
  set --
}
