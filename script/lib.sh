#!/bin/sh

set -e

uc_lib="$(dirname "$0")"
UCONF="$(dirname "$uc_lib")"
uname="$(uname)"
hostname="$(hostname -s | tr -s 'A-Z.' 'a-z-')"
test -x "$uc_lib"/init.sh || exit 99

. "$uc_lib"/std.lib.sh
. "$uc_lib"/str.lib.sh
. "$uc_lib"/util.lib.sh

test -n "$HOME" || err "no user dir" 100

init_conf()
{
  cp install/default.conf "$1"
  log "Initialized $1 from default install conf"
}

c_initialize()
{
  test -n "$1" || set -- install/$hostname.conf
  test -e "$1" || init_conf "$1"
  cat $1 | grep -v '^\s*\(#\|$\)' | while read directive arguments
  do
    local func_name="d_$(echo $directive|tr 'a-z' 'A-Z')_init"

    try_exec_func "$func_name" $(eval echo "$arguments") && {
      continue
    } || {
      err "init ret $? in $directive"
    }
  done
}

c_stat()
{
  test -n "$1" || set -- install/$hostname.conf
  test -e "$1" || err "no such install config $1" 1
  cat $1 | grep -v '^\s*\(#\|$\)' | while read directive arguments
  do
    local func_name="d_$(echo $directive|tr 'a-z' 'A-Z')_stat"

    try_exec_func "$func_name" $(eval echo "$arguments") && {
      continue
    } || {
      err "stat ret $? in $directive"
    }
  done
}

c_test()
{
  # Test script: run Bats tests
  ./test/*-spec.bats
}

d_SYMLINK_init()
{
  test -f "$1" || err "not a file: $1" 101
  test -e "$2" && {
    test -h "$2" && {
      test "$(readlink "$2")" = "$1" && {
        return 0
      } || {
        echo "rm symlink $2 and ln -s $1 $2"
      }
    } || {
      err "already exists and not a symlink: $1"
      return 2
    }
  } || {
    echo "TODO ln -s $1 $2"
  }
}

d_SYMLINK_stat()
{
  test -f "$1" || err "not a file: $1" 101
  test -e "$2" && {
    test -h "$2" && {
      test "$(readlink "$2")" = "$1" && {
        return 0
      } || {
        log "symlink changed: $2 $1: $(readlink "$2")"
      }
    } || {
      err "path exists and is not a symlink: $1"
      return 2
    }
  } || {
    echo "symlink missing: $2 to $1"
  }
}


d_COPY_init()
{
  test -f "$1" || err "not a file: $1" 101
  test -e "$2" && {
    test -f "$2" && {
      diff -bqr "$2" "$1" && {
        return 0
      } || {
        err "diffs in $2 $1"
        return 1
      }
    } || {
      err "already exists and not a file: $2"
      return 2
    }
  } || {
    echo "TODO cp $1 $2"
  }
}

d_COPY_stat()
{
  test -f "$1" || err "not a file: $1" 101
  test -e "$2" && {
    test -f "$2" && {
      diff -bqr "$2" "$1" && {
        return 0
      } || {
        err "diffs in $2 $1"
        return 1
      }
    } || {
      err "path already exists and not a file: $2"
      return 2
    }
  } || {
    echo "copy missing: $2 of $1"
  }
}


