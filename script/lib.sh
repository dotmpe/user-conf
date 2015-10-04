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
. "$uc_lib"/os.lib.sh
. "$uc_lib"/date.lib.sh
. "$uc_lib"/util.lib.sh

test -n "$HOME" || err "no user dir" 100

# config holds directives for current env/host,
c_initialize()
{
  cd "$UCONF" || err "? cd $UCONF" 1
  local conf=install/$hostname.u-c
  test ! -e "$conf" || {
    note "Already initialized: $conf"
    return
  }
  local uname=$(uname -s) machine=$(uname -m) tpl=
  test -n "$1" || set -- "default"
  for tag in $machine $uname $1
  do
    tpl="install/boilerplate-$tag.u-c"
    test ! -e "$tpl" || {
      cp $tpl $conf
      note "Initialized $hostname from $tag: $conf"
      break
    }
    for path in install/boilerplate-$tag*.u-c
    do
      test -e "$path" || continue
      echo "Found path for $tag: $path"
      printf "Use? [yN] " use
      read -r use
      case "$use" in Y|y)
        cp $path $conf
        note "Initialized $hostname from $tag: $conf"
        return
      esac
    done
  done
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
    prep_dir_func "$installer" || continue
    test -n "$arguments" || err "expected $installer packages" 1
    try_exec_func "$func_name" $arguments && {
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

# Update host from provision and config directives
c_update()
{
  local conf= func_name= arguments=
  rm -f /tmp/uc-update-failed
  cd "$UCONF" || err "? cd $UCONF" 1
  req_conf
  cat "$conf" | grep -v '^\s*\(#\|$\)' | while read directive arguments_raw
  do
    prep_dir_func update || continue
    try_exec_func "$func_name" $arguments && {
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

# Compare host with provision and config directives
c_stat()
{
  local conf= func_name= arguments=
  rm -f /tmp/uc-stat-failed
  cd "$UCONF" || err "? cd $UCONF" 1
  req_conf
  cat "$conf" | grep -v '^\s*\(#\|$\)' | while read directive arguments_raw
  do
    prep_dir_func stat || continue
    try_exec_func "$func_name" $arguments && {
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
  grep -iq "^BASE\ $p_\ " "$conf" && {
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

# Run tests, some unittests on the Sh library
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
  test -f "$1" -o -d "$1" || err "not a file or directory: $1" 101
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
    log "New symlink $1 $2"
  }
}

d_SYMLINK_stat()
{
  test -f "$1" -o -d "$1" || err "not a file or directory: $1" 101
  test -e "$2" && {
    test -h "$2" && {
      test "$(readlink "$2")" = "$1" && {
        return 0
      } || {
        log "Symlink changed: $2 $1: $(readlink "$2")"
      }
    } || {
      err "path exists and is not a symlink: $1"
      return 2
    }
  } || {
    log "Symlink missing: $2 to $1"
  }
}

## Copy directive

d_COPY_update()
{
  test -f "$1" || err "not a file: $1" 101
  test -e "$2" && {
    test -d "$2" && set -- "$1" "$2/$(basename $1)" || noop
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
    log "New copy $1 $2"
  }
}

d_COPY_stat()
{
  test -f "$1" || err "not a file: $1" 101
  test -e "$2" && {
    test -d "$2" && set -- "$1" "$2/$(basename $1)" || noop
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
    log "copy missing: $2 of $1"
  }
}


## Web directive (cURL)

d_WEB()
{
  test -n "$1" || err "expected url" 1
  test -n "$2" || err "expected target path" 1
  test -z "$4" || err "surplus params: '$4'" 1

  test -d "$2" -o \( ! -e "$2" -a -d "$(dirname "$2")" \) \
    || err "target must be existing directory or a new name in one: $2" 1

  test -d "$2" && {
      test "$(basename "$1")" != "$1" \
        || err "cannot get target basename from URL '$1', please provide full path" 1
      set -- "$1" "$2/$(basename $1 .git)" "$3"
  }

  echo "TODO web $@"
}

d_WEB_update()
{
  RUN=update d_WEB "$@" || return $?
}

d_WEB_stat()
{
  RUN=stat d_WEB "$@" || return $?
}


## GIT directive

d_GIT()
{
  test -n "$1" || err "expected url" 1
  test -n "$2" || err "expected target path" 1
  test -n "$3" || set -- "$1" "$2" "origin" "$4" "$5"
  test -n "$4" || set -- "$1" "$2" "$3" "master" "$5"
  test -n "$5" || set -- "$1" "$2" "$3" "$4" "clone"
  test -z "$6" || err "surplus params: '$6'" 1

  test -d "$2" -o \( ! -e "$2" -a -d "$(dirname "$2")" \) \
    || err "target must be existing directory or a new name in one: $2" 1

  test ! -e "$2/.git" && url= || {
    url="$(cd "$2"/;git config --get remote.$3.url)"
    test "$url" = "$1" || {
      err "Checkout exists at path $2 for <$url> not <$1>"
      return 1
    }
  }

  test ! -e "$2" -a -d "$(dirname "$2")" || {
    test -e "$2/.git" && {
      url="$(cd "$2"/;git config --get remote.$3.url)"
      test "$url" = "$1" || {
        err "Checkout exists at path $2 for <$url> not <$1>"
        return 1
      }
    } || {
      test "$(basename "$1" .git)" != "$1" \
        || err "cannot get target basename from GIT '$1', please provide full checkout path" 1
      set -- "$1" "$2/$(basename $1 .git)" "$3" "$4" "$5"
    }
  }

  req_git_age

  case "$5" in
    clone )
      test -e "$2/.git" && {
        cd $2; git diff --quiet && {
          younger_than $2/.git/FETCH_HEAD $GIT_AGE || {
            info "Updating $2 from remote $3"
            git fetch -q $3 2>/dev/null || { err "Error fetching remote $3 for $2"; return 1; }
          }
          git diff --quiet $3/$4 && {
            info "Checkout $2 clean and up-to-date"
          } || {
            test "$4" = "master" \
              && note "Updates for $2 remote $3" \
              ||note "Updates for $2 remote $3 (at branch $4)"
          }
          #remote=$(git ls-remote $3 heads/$4)
          #git rev-list --left-right ${local}...${remote} 
        } || {
          warn "Checkout at $2 looks dirty"
          return 1
        }
      } || {
        note "Checkout missing at $2"
        #echo git $5 "$1" "$2" --origin $3 --branch $4 
      } ;;
    * ) err "Invalid GIT mode $5"; return 1 ;;
  esac
}

d_GIT_stat()
{
  RUN=stat d_GIT "$@" || return $?
}

d_GIT_update()
{
  RUN=update d_GIT "$@" || return $?
}


## Meta

d_ENV_exec()
{
  export $@
}

d_SH_exec()
{
  eval $@
}

d_AGE_exec()
{
  test -n "$1" || err "expected additional property for age" 1
  test -n "$2" || err "expected age" 1
  test -z "$3" || err "surplus params: '$3'" 1
  set -- "$(echo $1 | tr 'a-z' 'A-Z')" "$2"
  case "$1" in
    GIT )
      GIT_AGE="$2"
      note "Max. GIT remote ref age set to $GIT_AGE seconds"
    ;;
  esac
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

d_INSTALL_OPKG()
{
  opkg update >/dev/null
  opkg install "$@"
}


# Misc. utils
req_conf() {
  conf=install/$hostname.u-c
  test -e "$conf" || err "no such user-config $conf" 1
}

prep_dir_func() {
  test -n "$directive" || err "empty directive" 1
  directive="$(echo "$directive"|tr 'a-z' 'A-Z')"
  arguments="$(eval echo "$arguments_raw")"

  case $directive in

    # base and bin are global settings, not processed in sequence
    BIN | BASE )
      func_name=
      return 1
      ;;

    # XXX install is not a provision directive yet
    INSTALL )
      case $1 in stat|update) return 1 ;; esac
      func_name="d_${directive}_$1"
      ;;

    # provision directives support stat or update
    COPY | SYMLINK | GIT | WEB )
      func_name="d_${directive}_$1"
      ;;

    ENV | AGE | SH ) # Update env; always updates
      func_name="d_${directive}_exec"
      ;;

    * ) err "Unknown directive $directive" 1 ;;

  esac
}

req_git_age()
{
  #grep -qi '^AGE\ GIT\ ' && {
  #  age_expr=$(echo $(grep -i '^AGE\ GIT\ ') | cut -d ' ' -f 3)
  #  # TODO: parse some expression for age: 1h 5min 5m etc.
  #  GIT_AGE="$age_expr"
  #} || noop

  test -n "$GIT_AGE" || {
    GIT_AGE=$_5MIN
    note "Max. GIT remote ref age set to $GIT_AGE seconds"
  }
}

