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
. "$sh_lib"/conf.lib.sh

test -n "$UCONF" || UCONF="$(dirname "$sh_lib")"

test -n "$HOME" || error "no user dir set" 100
test -e "$HOME" || error "no user dir" 100


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
test -n "$verbosity" || verbosity=5

stdio_type 0
stdio_type 1
stdio_type 2

# setup default options
test -n "$choice_interactive" || {
  case "$stdio_1_type" in t )
    choice_interactive=true ;;
  esac
}


# User-config holds directives for current env/host, make a copy to
# install/$hostname.u-c of the first existing path in
# boilerplate-{$machine,$uname,$domain,default}.u-c
c_initialize()
{
  test "$hostname.$domain" = "$(hostname)" || {
    echo "$hostname.$domain" > $HOME/.domain
  }
  test -n "$UCONF" || echo "? $UCONF" 1
  cd "$UCONF" || echo "? cd $UCONF" 1
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
  exec_dirs install $1 || return $?
}

# Update host from provision and config directives
c_update()
{
  exec_dirs update $1 || return $?
}

# Compare host with provision and config directives
c_stat()
{
  exec_dirs stat "$1" || return $?
}

# Add a new path to config (COPY directive only)
# XXX: looks like bashisms
c_add()
{
  test -f "$1" || error "? expected file argument" 1
  local pwd=$(pwd) conf=
  #cd $UCONF || error "? cd $UCONF" 1
  req_conf
  test -e "$1" && toadd=$1 || toadd=$pwd/$1
  test -e "$conf" || error "no such install config $conf" 1

  #exec_dirs base

  basename="$(basename "$toadd")"
  basedir="$(dirname "$toadd")"
  match_grep_pattern_test "$basedir"
  grep -iq "^BASE\ $p_\ " "$conf" && {
    ucbasedir_raw="$(grep "^\s*BASE\ $p_\ " "$conf" | cut -d ' ' -f 3 )"
    test -n "$ucbasedir_raw" || error "error parsing BASE directive for $basedir" 1
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
  test -n "$UCONF" || error "? $UCONF=" 1
  cd $UCONF || error "? cd $UCONF" 1
  # Test script: run Bats tests
  ./test/*-spec.bats
}


### Directive commands

## Symlink directive

d_SYMLINK()
{
  test -f "$1" -o -d "$1" || error "not a file or directory: $1" 101
  # target is either existing dir or non-existing filename in dir
  test -e "$2" && {
    test -h "$2" || {
      test -d "$2" && {
        set -- "$1" "$2/$(basename $1)"
      } || {
        error "expected directory or symlink"
        return 1
      }
    }
  } || {
    test -d "$(dirname $2)" || {
      error "no parent dir for target path $2"
      return 1
    }
  }
  # remove broken link first
  test ! -h "$2" -o -e "$2" || {
    log "Broken symlink $2"
    case "$RUN" in
      stat )
        return 2
        ;;
      update )
        rm "$2"
        ;;
    esac
  }
  # create or update link
  test -e "$2" && {
    test -h "$2" && {
      test "$(readlink "$2")" = "$1" && {
        return 0
      } || {
        case "$RUN" in
          stat )
            log "Symlink changed '$2' -> {$1,$(readlink "$2")}"
            return 2 ;;
          update )
            rm "$2"
            ln -s "$1" "$2"
            log "Updated symlink '$2' -> '$1'"
          ;;
        esac
      }
    } || {
      error "Path already exists and not a symlink '$2'"
      return 2
    }
  } || {
    log "New symlink '$2' -> '$1'"
    case "$RUN" in
      stat )
        return 2
        ;;
      update )
        ln -s $1 $2
        ;;
    esac
  }
}

d_SYMLINK_update()
{
  RUN=update d_SYMLINK "$@" || return $?
}

d_SYMLINK_stat()
{
  RUN=stat d_SYMLINK "$@" || return $?
}


## Copy directive

d_COPY()
{
  test -f "$1" || error "not a file: $1" 101
  test -e "$2" && {
    test -d "$2" && set -- "$1" "$2/$(basename $1)" || noop
    test -f "$2" && {
      # Check existing COPY version
      GITDIR=$UCONF vc_gitdiff "$1" "$2" || {
        return $?
        #trueish $choice_interactive && {
        #  #echo | read -p 'Resolve using vimdiff?' resolve
        #  #case "$resolve" in y )
        #      vimdiff "$1" "$2"
        #  #esac
        #} || return 1
      }

      diff -bqr "$2" "$1" >/dev/null || {
        case "$RUN" in
          stat ) log "Updates for copy of '$1' at '$2'" ;;
          update ) cp "$1" "$2" ;;
        esac
      }
    } || {
      test -e "$2" && {
        error "Copy target path already exists and not a file '$2'"
        return 2
      } || noop
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
  test -n "$1" || error "expected url" 1
  test -n "$2" || error "expected target path" 1
  test -z "$4" || error "surplus params: '$4'" 1

  test -d "$2" -o \( ! -e "$2" -a -d "$(dirname "$2")" \) \
    || error "target must be existing directory or a new name in one: $2" 1

  test -d "$2" && {
      test "$(basename "$1")" != "$1" \
        || error "cannot get target basename from URL '$1', please provide full path" 1
      set -- "$1" "$2/$(basename $1 .git)" "$3"
  }

  case "$RUN" in update ) PREF= ;; stat ) PREF="echo '** DRY-RUN **: '" ;; esac

  test -e "$2" && {
    tmpf=/tmp/$(uuidgen)
    curl -sq $1 -o $tmpf || {
      error "Unable to fetch '$1' to $tmpf"
      return 1
    }
    test -e "$tmpf" || {
      error "Failed to fetch '$1' to $tmpf"
      return 1
    }

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
  test -n "$1" || error "expected url" 1
  test -n "$2" || error "expected target path" 1
  test -n "$3" || set -- "$1" "$2" "origin" "$4" "$5"
  test -n "$4" || set -- "$1" "$2" "$3" "master" "$5"
  test -n "$5" || set -- "$1" "$2" "$3" "$4" "clone"
  test -z "$6" || error "surplus params: '$6'" 1

  test -d "$2" -o \( ! -e "$2" -a -d "$(dirname "$2")" \) \
    || error "target must be existing directory or a new name in one: $2" 1

  test ! -e "$2/.git" || {
    req_git_remote "$1" "$2" "$3" || return $?
  }

  test ! -e "$2" -a -d "$(dirname "$2")" || {
    test -e "$2/.git" && req_git_remote "$1" "$2" "$3" || {
      test "$(basename "$1" .git)" != "$1" \
        || error "cannot get target basename from GIT '$1', please provide full checkout path" 1
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
          test -d "$gitdir" || error "cannot determine gitdir at '$2'" 1
          {
            test -e $gitdir/FETCH_HEAD && {
              younger_than $gitdir/FETCH_HEAD $GIT_AGE
            } || {
              note "No FETCH_HEAD in $2"
              test # break to '||' and do first-time fetch
            }
          } || {
            info "Fetching $2 branch $4 from remote $3"
            ${PREF}git fetch -q $3 $4 2>/dev/null || {
              error "Error fetching remote $3 for $2"; return 1; }
          }
          debug "Comparing $2 branch $4 with remote $3 ref"
          git diff --quiet && {
            git diff --quiet $3/$4..HEAD && {
              test "$4" = "master" \
                && info "Checkout $2 clean and up-to-date" \
                || info "Checkout $2 clean and up-to-date at branch $4"
            } || {
              warn "Checkout $2 clean but not in sync with $3 at branch $4"
              test # break and to co/pull
            }
          } || {
            ${PREF}git checkout $4
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

    * ) error "Invalid GIT mode $5"; return 1 ;;

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
  test -f "$1" || error "expected file path '$1'" 1
  test -n "$2" || error "expected one ore more lines" 1

  file=$1
  shift 1
  for line in "$@"
  do
    enable_setting $file "$line"
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
  set -- $@
  printf -- "export $@\n"
}

d_SH_exec()
{
  printf -- "$@\n"
}

d_BASH_exec()
{
  echo bash -c "'$@'"
}

d_AGE_exec()
{
  set -- $@
  test -n "$1" || error "expected additional property for age" 1
  test -n "$2" || error "expected age" 1
  test -z "$3" || error "surplus params: '$3'" 1
  set -- "$(echo $1 | tr 'a-z' 'A-Z')" "$2"
  case "$1" in
    GIT )
      printf "export GIT_AGE=$2"
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
  pip install $@
}

d_INSTALL_OPKG()
{
  opkg update >/dev/null
  opkg install "$@"
}


# Misc. utils
req_conf() {
  test -e Ucfile && conf=Ucfile \
    || test -e Userconf && conf=Userconf \
    || conf=install/$hostname.u-c
  test -e $conf && return
  cd $UCONF
  conf=install/$hostname.u-c
  test -e $conf || error "no such user-config $conf" 1
}

prep_dir_func() {
  test -n "$directive" || error "empty directive" 1
  directive="$(echo "$directive"|tr 'a-z' 'A-Z')"
  arguments="$arguments_raw"
  func_name=
  gen_eval=

  case $directive in

    # base and bin are global settings, not processed in sequence
    BIN | BASE )
      return 1
      ;;

    INSTALL )
      case $1 in stat|update) return 1 ;; esac
      packager=$(echo $arguments_raw | awk '{print $1}')
      func_name="d_${directive}_$(echo $packager | tr 'a-z' 'A-Z')"
      arguments="$(eval echo "$arguments_raw")"
      arguments="$(expr substr "$arguments" $(( 1 + ${#packager} )) ${#arguments} )"
      ;;

    # provision/config directives support stat or update
    COPY | SYMLINK | GIT | WEB | LINE )
      case $1 in install) return 1 ;; esac
      func_name="d_${directive}_$1"
      arguments="$(eval echo "$arguments_raw")"
      ;;

    ENV | AGE | SH | BASH ) # Update env; always updates
      gen_eval="d_${directive}_exec"
      ;;

    * ) error "Unknown directive $directive" 1 ;;

  esac
}

exec_dirs()
{
  local conf= func_name= arguments= diridx=0
  rm -f /tmp/uc-$1-failed
  req_conf

  cat "$conf" | grep -v '^\s*\(#\|$\)' | while read directive arguments_raw
  do
    diridx=$(( $diridx + 1 ))

    #printf -- "'$directive' '$arguments_raw'\n"
    # look for funtion or skip
    prep_dir_func $1 || continue
    #printf -- "'$directive' '$arguments_raw' '$arguments'\n"

    test -z "$2" || {
      # Skip if diridx requested
      test $diridx -lt $2 \
        && continue || test $2 -eq $diridx || return
    }

    test -n "$gen_eval" && {
      gen=$($gen_eval "$arguments")
      eval $gen && {
        info "evaluated $directive $arguments_raw"
        continue
      } || {
        error "$1 ret $? in $directive with '$arguments'"
        touch /tmp/uc-$1-failed
      }

    } || noop

    $func_name $arguments && {
      debug "executed $directive $arguments_raw"
      continue
    } || {
      error "$1 ret $? in $directive with '$arguments'"
      touch /tmp/uc-$1-failed
    }

  done

  test ! -e "/tmp/uc-$1-failed" || {
    rm -f /tmp/uc-$1-failed
    error "failed directives" 1
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
  test -n "$1" || error "expected url" 1
  test -d "$2" || error "expected checkout dir '$2'" 1
  test -n "$3" || set -- "$1" "$2" "origin"
  test -z "$4" || error "req-git-remote surplus arguments" 1

  gitdir="$(vc_gitdir "$2")"
  url="$(cd "$2"; git config remote.${3}.url)"
  test -n "$url" && {
    test "$url" = "$1" || {
      error "Checkout exists at path $2 for $3 <$url> not <$1>"
      return 1
    }
  } || {
    case "$RUN" in
      update )
        ( cd $2; git remote add $3 $1 ; git fetch --all )
        note "New remote $3 for $2";;
      stat ) error "No remote $3 at $2"; return 1;;
    esac
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

