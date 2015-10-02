#!/bin/sh

set -e

test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"
test -n "$UCONF" || UCONF="$(dirname "$uc_lib")"
test -n "$uname" || uname="$(uname)"
test -n "$hostname" || hostname="$(hostname -s | tr -s 'A-Z.' 'a-z-')"

# just a sanity check
test -s "$uc_lib"/lib.sh || exit 99
test -x "$uc_lib"/install.sh || exit 97
test -x "$uc_lib"/init.sh || exit 98
test -x "$uc_lib"/add.sh || exit 97
test -x "$uc_lib"/stat.sh || exit 96
test -x "$uc_lib"/update.sh || exit 95

. "$uc_lib"/std.lib.sh
. "$uc_lib"/str.lib.sh
. "$uc_lib"/match.lib.sh
. "$uc_lib"/util.lib.sh

test -n "$HOME" || err "no user dir" 100


# config holds directives for current env/host,
c_initialize()
{
  local conf=install/$hostname.conf
  cd "$UCONF" || err "? cd $UCONF" 1
  cp "install/default.conf" $conf
}

c_install()
{
  local conf= func_name= arguments=
  rm -f /tmp/uc-install-failed
  cd "$UCONF" || err "? cd $UCONF" 1
  req_conf
  cat "$conf" | grep -v '^\s*\(#\|$\)' | while read directive installer arguments_raw
  do
    test -n "$installer" || err "empty installer" 1
    installer="$(echo "$installer"|tr 'a-z' 'A-Z')"
    prep_dir_func "$installer" INSTALL || continue
    test -n "$arguments" || err "expected $installer packages" 1
    try_exec_func "$func_name" $(eval echo "$arguments") && {
      continue
    } || {
      err "install ret $? in $directive:$installer with '$arguments'"
      touch /tmp/uc-install-failed
    }
  done
  test ! -e "/tmp/uc-install-failed" || {
    rm -f /tmp/uc-install-failed
    err "failed directives" 1
  }
}

# Update paths from config
c_update()
{
  local conf= func_name= arguments=
  rm -f /tmp/uc-update-failed
  cd "$UCONF" || err "? cd $UCONF" 1
  req_conf
  cat "$conf" | grep -v '^\s*\(#\|$\)' | while read directive arguments_raw
  do
    prep_dir_func update
    case $directive in INSTALL | BASE ) continue ;; esac

    try_exec_func "$func_name" $(eval echo "$arguments") && {
      continue
    } || {
      err "update ret $r in $directive with '$arguments'"
      touch /tmp/uc-update-failed
    }
  done
  test ! -e "/tmp/uc-stat-failed" || {
    rm -f /tmp/uc-update-failed
    err "failed directives" 1
  }
}

# Compare config with paths
c_stat()
{
  local conf= func_name= arguments=
  rm -f /tmp/uc-stat-failed
  cd "$UCONF" || err "? cd $UCONF" 1
  req_conf
  cat "$conf" | grep -v '^\s*\(#\|$\)' | while read directive arguments_raw
  do
    prep_dir_func stat
    case $directive in INSTALL | BASE ) continue ;; esac
    #$source $0
    try_exec_func "$func_name" $(eval echo "$arguments") && {
      continue
    } || {
      err "stat ret $? in $directive with '$arguments'"
      touch /tmp/uc-stat-failed
    }
  done
  test ! -e "/tmp/uc-stat-failed" || {
    rm -f /tmp/uc-stat-failed
    err "failed directives" 1
  }
}

# Add a new path to config (COPY directive only)
c_add()
{
  test -f "$1" || err "? expected file argument" 1
  local pwd=$(pwd) conf=
  cd $UCONF || err "? cd $UCONF" 1
  req_conf
  test -e "$1" && toadd=$1 || toadd=$pwd/$1
  test -e "$conf" || err "no such install config $conf" 1
  basename="$(basename "$toadd")"
  basedir="$(dirname "$toadd")"
  match_grep_pattern_test "$basedir"
  grep -q "^\s*BASE\ $p_\ " "$conf" && {
    ucbasedir_raw="$(grep "^\s*BASE\ $p_\ " "$conf" | cut -d ' ' -f 3 )"
    test -n "$ucbasedir_raw" || err "error parsing BASE directive for $basedir" 1
    note "Found customized rcbase $ucbasedir_raw"
    ucbasedir=$(eval echo "$ucbasedir_raw")
  } || {
    ucbasedir="$UCONF/$(basename "$basedir")"
    ucbasedir_raw="\$UCONF/$(basename "$basedir")"
  }
  log "Adding $toadd to $ucbasedir_raw"
  test -d "$ucbasedir" || mkdir -vp "$ucbasedir"
  cp "$toadd" "$ucbasedir"
  git add "$ucbasedir/$basename"
  test "${1:0:${#HOME}}" = "$HOME" && {
    echo "COPY $ucbasedir_raw/$basename \$HOME/${1:$(( ${#HOME} + 1))}" >> "$conf"
  } || {
    echo "COPY $ucbasedir_raw/$basename $toadd" >> "$conf"
  }
  git add "$conf"
  git st
}

# Test the Sh library
c_test()
{
  cd $UCONF || err "? cd $UCONF" 1
  # Test script: run Bats tests
  ./test/*-spec.bats
}


### Directive commands

## Symlink directive

d_SYMLINK_update()
{
  test -f "$1" || err "not a file: $1" 101
  test -e "$2" && {
    test -h "$2" && {
      test "$(readlink "$2")" = "$1" && {
        return 0
      } || {
        rm "$2"
        ln -s "$1" "$2"
        log "Updated symlink $1"
      }
    } || {
      err "Path already exists and not a symlink: $1"
      return 2
    }
  } || {
    ln -s $1 $2
    echo "New symlink $1 $2"
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
        rm "$2"
        log "Symlink changed: $2 $1: $(readlink "$2")"
      }
    } || {
      err "path exists and is not a symlink: $1"
      return 2
    }
  } || {
    echo "Symlink missing: $2 to $1"
  }
}

## Copy directive

d_COPY_update()
{
  test -f "$1" || err "not a file: $1" 101
  test -e "$2" && {
    test -f "$2" && {
      diff -bqr "$2" "$1" >/dev/null && {
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
    cp "$1" "$2"
    echo "New copy $1 $2"
  }
}

d_COPY_stat()
{
  test -f "$1" || err "not a file: $1" 101
  test -e "$2" && {
    test -f "$2" && {
      diff -bqr "$2" "$1" >/dev/null && {
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


## Installers

d_INSTALL_APT()
{
  sudo apt-get install "$@"
}

d_INSTALL_BREW()
{
  brew install "$@"
}

d_INSTALL_PIP()
{
  pip install "$@"
}


# Misc. utils
req_conf() {
  conf=install/$hostname.conf
  test -e "$conf" || err "no such install config $conf" 1
}

prep_dir_func() {
  test -n "$directive" || err "empty directive" 1
  directive="$(echo "$directive"|tr 'a-z' 'A-Z')"
  arguments="$(eval echo "$arguments_raw")"
  func_name="d_${directive}_$1"
  test -z "$2" && return 0 || {
    case "$directive" in $2 ) return 0;; * ) return 1;; esac
  }
}

