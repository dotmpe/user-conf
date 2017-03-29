#!/bin/sh

# Sys: lower level Sh helpers; dealing with vars, functions, and other shell
# ideosyncracities

set -e

# No-Op(eration)
noop()
{
  #. /dev/null # source empty file
  #echo -n # echo nothing
  #printf "" # id. if echo -n incompatible
  set -- # clear arguments to this function
  #return # since we're in a function
}

# Error unless non-empty and true-ish
trueish()
{
  test -n "$1" || return 1
  case "$1" in
    [Oo]n|[Tt]rue|[Yyj]|[Yy]es|1)
      return 0;;
    * )
      return 1;;
  esac
}

