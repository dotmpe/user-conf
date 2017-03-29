#!/bin/sh

set -e


lib_load()
{
  local f_lib_load=
  test -n "$__load_lib" || local __load_lib=1
  test -n "$1" || set -- str sys os std src match
  while test -n "$1"
  do
    . $scriptpath/$1.lib.sh load-ext
    f_lib_load=$(printf "${1}" | tr -Cs 'A-Za-z0-9_' '_')_load
    # func_exists, then call
    type ${f_lib_load} 2> /dev/null 1> /dev/null && {
      ${f_lib_load}
    }
    shift
  done
}

# Id: user-conf/0.0.1-dev script/util.lib.sh
# From: script-mpe/0.0.4-dev util.sh
