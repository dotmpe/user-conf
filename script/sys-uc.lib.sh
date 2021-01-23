#!/usr/bin/env bash

## Sys: dealing with vars, functions, env.

sys_uc_lib_load()
{
  true "${uname:="$(uname -s | tr '[:upper:]' '[:lower:]')"}"
  true "${hostname:="$(hostname -s | tr 'A-Z' 'a-z')"}"
}

# Error unless non-empty and true-ish
trueish () # Str
{
  test -n "$1" || return 1
  case "$1" in
    [Oo]n|[Tt]rue|[Yyj]|[Yy]es|1)
      return 0;;
    * )
      return 1;;
  esac
}
