#!/bin/sh

set -e

# some sanity checks
test -s "$uc_lib"/lib.sh || exit 99
test -x "$uc_lib"/install.sh || exit 97
test -x "$uc_lib"/init.sh || exit 98
test -x "$uc_lib"/add.sh || exit 97
test -x "$uc_lib"/stat.sh || exit 96
test -x "$uc_lib"/update.sh || exit 95

test -n "$sh_lib" || sh_lib="$(dirname $uc_lib)"

. "$sh_lib"/std.lib.sh
. "$sh_lib"/str.lib.sh
. "$sh_lib"/match.lib.sh
. "$sh_lib"/os.lib.sh
. "$sh_lib"/date.lib.sh
. "$sh_lib"/vc.lib.sh
. "$sh_lib"/util.lib.sh

test -n "$UCONF" || UCONF="$(dirname "$sh_lib")"

test -n "$HOME" || err "no user dir set" 100
test -e "$HOME" || err "no user dir" 100


test -n "$uname" || uname="$(uname -s)"
test -n "$machine" || machine="$(uname -m)"
test -n "$hostname" || {
  test -e $HOME/.domain &&  {
    hostname=$(cat $HOME/.domain | sed 's/^\([^\.]*\)\..*$/\1/g')
    domain=$(cat $HOME/.domain | sed 's/^[^\.]*\.//g')
  } || {
    hostname="$(hostname -s | tr 'A-Z.' 'a-z-' | tr -s '-' '-' )"
  }
}
test -n "$verbosity" || verbosity=4


# config holds directives for current env/host,
c_initialize()
{
  test "$hostname.$domain" = "$(hostname)" || {
    echo "$hostname.$domain" > $HOME/.domain
  }

  cd "$UCONF" || err "? cd $UCONF" 1
  local conf=install/$hostname.u-c
  test ! -e "$conf" && {
    note "Initializing $hostname: $conf"
  } || {
    note "Already initialized: $conf"
    return
  }
  local tpl=
  for tag in $machine $uname $hostname default
  do
    tpl="install/boilerplate-$tag.u-c"
    test ! -e "$tpl" || {
      cp -v $tpl $conf
      note "Initialized $hostname"
      break
    }
    for path in install/boilerplate-$tag*.u-c
    do
      test -e "$path" || continue
      echo "Found path for tag '$tag': $path"
      printf "Use? [yN] " use
      read -r use
      case "$use" in Y|y)
        cp -v $path $conf
        note "Initialized $hostname"
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
  exec_dirs update
}

# Compare host with provision and config directives
c_stat()
{
  exec_dirs stat
}

# Add a new path to config (COPY directive only)
# XXX: looks like bashisms
c_add()
{
  test -f "$1" || err "? expected file argument" 1
  local pwd=$(pwd) conf=
  cd $UCONF || err "? cd $UCONF" 1
  req_conf
  test -e "$1" && toadd=$1 || toadd=$pwd/$1
  test -e "$conf" || err "no such install config $conf" 1

  exec_dirs base

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
  git status
}

# Run tests, some unittests on the Sh library
c_test()
{
  test -n "$UCONF" || err "? $UCONF=" 1
  cd $UCONF || err "? cd $UCONF" 1
  # Test script: run Bats tests
  ./test/*-spec.bats
}


### Directive commands

## Symlink directive

d_SYMLINK_update()
{
  test -f "$1" -o -d "$1" || err "not a file or directory: $1" 101
  test ! -h "$2" -o -e "$2" || {
    rm "$2"
    info "removed broken symlink"
  }
  test -e "$2" && {
    test -h "$2" && {
      test "$(readlink "$2")" = "$1" && {
        return 0
      } || {
        rm "$2"
        ln -s "$1" "$2"
        log "Updated symlink '$2' -> '$1'"
      }
    } || {
      err "Path already exists and not a symlink '$2'"
      return 2
    }
  } || {
    ln -s $1 $2
    log "New symlink '$2' -> '$1'"
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
        log "Symlink changed '$2' -> {$1,$(readlink "$2")}"
        return 1
      }
    } || {
      err "Path already exists and not a symlink '$2'"
      return 2
    }
  } || {
    log "Missing symlink '$2' -> '$1'"
    return 1
  }
}

## Copy directive

d_COPY()
{
  test -f "$1" || err "not a file: $1" 101
  test -e "$2" && {
    test -d "$2" && set -- "$1" "$2/$(basename $1)" || noop
    test -f "$2" && {
      GITDIR=$UCONF vc_gitdiff "$1" "$2" || return $?
      diff -bqr "$2" "$1" >/dev/null || {
        case "$RUN" in
          stat ) log "Updates for copy of '$1' at '$2'" ;;
          update ) cp "$1" "$2" ;;
        esac
      }
    } || {
      err "Copy target path already exists and not a file '$2'"
      return 2
    }
  } || {
    case "$RUN" in
      stat )
        log "Missing copy of '$1' at '$2'"
        return 1
        ;;
      update )
        cp "$1" "$2"
        log "New copy of '$1' at '$2'"
        ;;
    esac
  }
}

d_COPY_update()
{
  RUN=update d_COPY "$@" || return $?
}

d_COPY_stat()
{
  RUN=stat d_COPY "$@" || return $?
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

  case "$RUN" in update ) PREF= ;; stat ) PREF="echo '** DRY-RUN **: '" ;; esac

  test -e "$2" && {
    tmpf=/tmp/$(uuidgen)
    curl -sq $1 -o $tmpf
    diff -bq $2 $tmpf && {
      info "Up to date with web at $2"
    } || {
      ${PREF}cp $tmpf $2
      note "Updated $2 from $1"
      case "$RUN" in update ) ;; * ) return 1 ;; esac
    }
  } || {
    ${PREF}curl -sq $1 -o $2
    note "New path $2 from $1"
    case "$RUN" in update ) ;; * ) return 1 ;; esac
  }
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

  test ! -e "$2/.git" || {
    req_git_remote "$1" "$2" "$3" || return $?
  }

  test ! -e "$2" -a -d "$(dirname "$2")" || {
    test -e "$2/.git" && req_git_remote "$1" "$2" "$3" || {
      test "$(basename "$1" .git)" != "$1" \
        || err "cannot get target basename from GIT '$1', please provide full checkout path" 1
      set -- "$1" "$2/$(basename $1 .git)" "$3" "$4" "$5"
    }
  }

  req_git_age

  case "$RUN" in update ) PREF= ;; stat ) PREF="echo '** DRY-RUN **: '" ;; esac

  case "$5" in

    clone )
      test -e "$2/.git" && {
        cd $2; git diff --quiet && {
          gitdir="$(vc_gitdir)"
          test -d "$gitdir" || err "cannot determine gitdir at '$2'" 1
          {
            test -e $gitdir/FETCH_HEAD && {
              younger_than $gitdir/FETCH_HEAD $GIT_AGE
            } || {
              note "No FETCH_HEAD in $2"
            }
          } || {
            info "Fetching $2 branch $4 from remote $3"
            ${PREF}git fetch -q $3 $4 2>/dev/null || {
              err "Error fetching remote $3 for $2"; return 1; }
          }
          debug "Comparing $2 branch $4 with remote $3 ref"
          git diff --quiet && {
            git diff --quiet $3/$4..HEAD && {
              test "$4" = "master" \
                && info "Checkout $2 clean and up-to-date" \
                || info "Checkout $2 clean and up-to-date at branch $4"
            } || {
              test "$4" = "master" \
                && warn "Checkout $2 clean but ahead of $3" \
                || warn "Checkout $2 clean but ahead of $3 at branch $4"
              return 1
            }
          } || {
            ${PREF}git co $4
            ${PREF}git pull $3 $4
            test "$4" = "master" \
              && note "Updated $2 from remote $3" \
              || note "Updated $2 from remote $3 (at branch $4)"
            case "$RUN" in update ) ;; * ) return 1 ;; esac
          }
        } || {
          test "$4" = "master" \
            && warn "Checkout at $2 looks dirty" \
            || warn "Checkout of $4 at $2 looks dirty"
          return 1
        }
      } || {
        test "$4" = "master" \
          && note "Checkout missing at $2" \
          || note "Checkout of $4 missing at $2"
        ${PREF}git $5 "$1" "$2" --origin $3 --branch $4
        case "$RUN" in update ) ;; * ) return 1 ;; esac
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


## LINE directive

d_LINE()
{
  test -f "$1" || err "expected file path" 1
  test -n "$2" || err "expected one ore more lines" 1

  shift 1
  for line in "$@"
  do
    echo $line
  done
}

d_LINE_stat()
{
  RUN=stat d_LINE "$@" || return $?
}

d_LINE_update()
{
  RUN=update d_LINE "$@" || return $?
}



## Meta

d_ENV_exec()
{
  echo export "$@"
}

d_SH_exec()
{
  echo "$@"
}

d_BASH_exec()
{
  echo bash -c "$@"
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
      note "Max. GIT remote ref age to $2 seconds"
    ;;
  esac
}


## Installers

d_INSTALL_APT()
{
  sudo apt-get install -qq -y "$@"
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
  func_name=
  gen_eval=

  case $directive in

    # base and bin are global settings, not processed in sequence
    BIN | BASE )
      return 1
      ;;

    # XXX install is not a provision directive yet
    INSTALL )
      case $1 in stat|update) return 1 ;; esac
      func_name="d_${directive}_$1"
      ;;

    # provision/config directives support stat or update
    COPY | SYMLINK | GIT | WEB | LINE )
      func_name="d_${directive}_$1"
      ;;

    ENV | AGE | SH | BASH ) # Update env; always updates
      gen_eval="d_${directive}_exec"
      ;;

    * ) err "Unknown directive $directive" 1 ;;

  esac
}

exec_dirs()
{
  local conf= func_name= arguments=
  rm -f /tmp/uc-$1-failed
  cd "$UCONF" || err "? cd $UCONF" 1
  req_conf

  cat "$conf" | grep -v '^\s*\(#\|$\)' | while read directive arguments_raw
  do
    prep_dir_func $1 || continue

    test -n "$gen_eval" && {
      eval "$($gen_eval $arguments_raw)" && {
        continue
      } || {
        err "$1 ret $? in $directive with '$arguments'"
        touch /tmp/uc-$1-failed
      }
    } || noop

    try_exec_func "$func_name" $arguments && {
      continue
    } || {
      err "$1 ret $? in $directive with '$arguments'"
      touch /tmp/uc-$1-failed
    }

  done

  test ! -e "/tmp/uc-$1-failed" || {
    rm -f /tmp/uc-$1-failed
    err "failed directives" 1
  }
}

# Get or set default GIT age
req_git_age()
{
  # XXX AGE is eval'd in sequence, seems convenient for some meta dirs
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

req_git_remote()
{
  test -n "$1" || err "expected url" 1
  test -d "$2" || err "expected checkout dir '$2'" 1
  test -n "$3" || set -- "$1" "$2" "origin"
  test -z "$4" || err "req-git-remote surplus arguments" 1

  gitdir="$(vc_gitdir "$2")"
  url="$(cd "$2"; git config remote.${3}.url)"
  test -n "$url" || {
    case "$RUN" in
      update ) git remote add $3 $1; note "New remote $3 for $2";;
      stat ) err "No remote $3 at $2"; return 1;;
    esac
  }
  test "$url" = "$1" || {
    err "Checkout exists at path $2 for $3 <$url> not <$1>"
    return 1
  }
}

c_commit()
{
  test "$(pwd)" = "$UCONF" || cd $UCONF
  git diff --quiet && {
    git commit -m "At $hostname"
    git pull
    git push
  } || {
    error "dir looks dirty"
  }
}

