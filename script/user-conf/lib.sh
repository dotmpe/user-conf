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
. "$sh_lib"/src.lib.sh
. "$sh_lib"/match.lib.sh
. "$sh_lib"/os.lib.sh
. "$sh_lib"/date.lib.sh
. "$sh_lib"/vc.lib.sh
. "$sh_lib"/sys.lib.sh
. "$sh_lib"/conf.lib.sh

test -n "$UCONF" || UCONF="$UCONFDIR"
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
test -n "$username" || username=$(whoami)
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
  test -n "$domain" || domain=default
  test "$hostname.$domain" = "$(hostname)" || {
    echo "$hostname.$domain" > $HOME/.domain
  }
  test -n "$UCONF" || echo "? $UCONF" 1
  cd "$UCONF" || echo "? cd $UCONF" 1
  local conf=install/$hostname.u-c \
    local_name_conf=local-$hostname-$domain.u-c \
    local_conf=local.u-c

  test -e "install/$local_name_conf" && {
    test "$(readlink install/$local_name_conf)" = "$(basename $conf)" ||
      rm install/$local_name_conf
  }
  test -e "install/$local_name_conf" ||
    ln -s $(basename $conf) install/$local_name_conf

  test -e "install/$local_conf" && {
    test "$(readlink install/$local_conf)" = "$local_name_conf" ||
      rm install/$local_conf
  }
  test -e "install/$local_conf" ||
    ln -s $local_name_conf install/$local_conf

  test ! -e "$conf" || {
    note "Already initialized: $conf"
    return
  }
  local tpl=
  for tag in $machine $uname $hostname default
  do
    tpl="install/boilerplate-$tag.u-c"
    test ! -e "$tpl" || {
      cp -v $tpl $conf
      note "Initialized $hostname from $tag boilerplate"
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
  local conf=
  req_conf
  exec_dirs install "$1" $conf || return $?
}

# Update host from provision and config directives
c_update()
{
  local conf=
  req_conf
  exec_dirs update "$1" $conf || return $?
}

# Compare host with provision and config directives
# 1:diridx
c_stat()
{
  local conf=
  req_conf
  exec_dirs stat "$1" $conf || return $?
}

# Add a new path to config (COPY directive only)
# XXX: looks like bashisms
c_add()
{
  case "$1" in
    SYMLINK|COPY ) ;;
    * ) echo "? expected valid directive, not '$1'"; exit 1 ;; esac
  test -f "$2" || error "? expected file argument '$2'" 1

  # Best effort to get canonical path
  local basename="$(basename "$2")" \
    basedir="$(cd $(dirname "$2"); pwd -P)"
  # Start off u-c env
  local pwd=$(pwd) conf=
  req_conf

  local toadd=$basedir/$basename

  # Look if any BASE direct matches source path, use that
  # mapping for the target path inside the repository
  #exec_dirs base
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

  test "${2:0:${#HOME}}" = "$HOME" && {
    echo "$1 $ucbasedir_raw/$basename \$HOME/${2:$(( ${#HOME} + 1))}" >> "$conf"
  } || {
    echo "$1 $ucbasedir_raw/$basename $toadd" >> "$conf"
  }
  # Add file to index and show state
  git add "$conf"

  git -c color.status=always status
}

c_copy()
{
  c_add COPY "$1"
}
c_symlink()
{
  c_add SYMLINK "$1"
}

# Run tests, some unittests on the Sh library
c_test()
{
  test -n "$UCONF" || error "? $UCONF=" 1
  cd $UCONF || error "? cd $UCONF" 1
  # Test script: run Bats tests
  bats ./test/*-spec.bats
}


### Directive commands

## Symlink directive

d_SYMLINK()
{
  test -f "$1" -o -d "$1" || {
    error "not a file or directory: $1"
    return 1
  }
  # target is either existing dir or non-existing filename in dir
  test -e "$2" && {
    test -h "$2" || {
      test -d "$2" && {
        set -- "$1" "$2/$(basename $1)"
      } || {
        error "expected directory or symlink: $2"
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

d_COPY() # SCM-Src-File Host-Target-File
{
  test -e "$1" &&
    set -- "$(realpath "$1")" "$2"
  test -f "$1" || {
    error "not a file: $1"
    return 1
  }

  test -e "$2" -a -d "$2" && {
      copy_target="$(normalize_relative "$2/$(basename "$1")")"
      debug "Expanding '$2' to '$copy_target'"
      set -- "$1" "$copy_target"
  } || noop

  test -e "$2" && {

    stat=0
    test -f "$2" && {
      diff_copy "$1" "$2" || { stat=$?
        diff -q "$1" "$2" && {
           warn "Changes resolved but uncommitted for 'COPY \"$1\" \"$2\"'"
           return
        }
        # Check existing COPY version
        trueish $choice_interactive && {
          vimdiff "$1" "$2" </dev/tty >/dev/tty ||
            warn "Interactive Diff still non-zero ($?)"
        } || return 1
      }
    } || {
      test ! -f "$2" && {
        error "Copy target path already exists and not a file '$2'"
        return 2
      }
    }

    case "$stat" in
      0 )
          info "Up to date with '$1' at '$2'"
          return
        ;;
      2 )
          warn "Unknown state of '$1' for path '$2'"
          return 2
        ;;
    esac

    case "$RUN" in
      stat )
          note "Out of date with '$1' at '$2'"
          return 1
        ;;
      update )
          cp "$1" "$2" || {
            log "Copy to $2 failed"
            return 1
          }
        ;;
    esac

  } || {

    case "$RUN" in
      stat )
        log "Missing copy of '$1' at '$2'"
        return 1
        ;;
      update )
        cp "$1" "$2" &&
        log "New copy of '$1' at '$2'" || {
          warn "Unable to copy '$1' at '$2'"
          return 1
        }
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
              newer_than $gitdir/FETCH_HEAD $GIT_AGE
            } || {
              info "No FETCH_HEAD in $2"
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

# print missing/mismatching packages
d_INSTALL_list_APT()
{
  out=/tmp/bin-apt-installed.list
  dpkg-query -l >$out
  for pack in $@
  do
    grep -q '^ii\s*'$pack'\>' $out || echo $pack
  done
}

d_INSTALL_list_BREW()
{
  echo $@
}

d_INSTALL_list_PIP()
{
  out=/tmp/bin-pip-installed.list
  pip list >$out
  for pack in $@
  do
    grep -qi '^'$pack'\>\ ' $out || echo $pack
  done
}

d_INSTALL_list_OPKG()
{
  echo $@
}

d_INSTALL_list_BIN()
{
  echo $@
}

# install using package manager
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

d_INSTALL_BIN()
{
  echo $@
}


# Misc. utils

# get conf env, and chdir to user-conf repo-checkout dir.
req_conf() {
  test -e Ucfile && conf=Ucfile \
    || test -e Userconf && conf=Userconf \
    || conf=install/$hostname.u-c
  test -e $conf && return
  cd $UCONF
  conf=install/$hostname.u-c
  test -e $conf || error "no such user-config $conf" 1
  conf="$(echo $conf $(verbose=false exec_dirs include $conf))"
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
      arguments="$(eval echo "$arguments_raw")"
      arguments="$(echo "$arguments" | cut -c$(( 2 + ${#packager} ))-${#arguments} )"

      test "$packager" = "*" && {
        for packager in APT BREW PIP OPKG
        do
          func_name="d_INSTALL_$packager"
          d_INSTALL_list_$packager "$arguments"
        done
      } || {
        packager="$(echo $packager | tr 'a-z' 'A-Z')"
        func_name="d_INSTALL_$packager"
        arguments="$(d_INSTALL_list_$packager "$arguments")"
      }
      test -n "$arguments" && {
        note "#$diridx $packager missing packages: $arguments"
      } || {
        info "Nothing to install for #$diridx $packager"
        return 1
      }
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

    INCLUDE )
      case $1 in include) ;; * ) return ;; esac
      arguments="$(eval echo "$arguments_raw")"
      echo $arguments
      ;;

    * ) error "Unknown directive $directive" 1 ;;

  esac
}

# Eval/
exec_dirs()
{
  local dirs=$1 func_name= arguments= diridx=0 idx=$2
  shift 2
  rm -f /tmp/uc-$dirs-passed /tmp/uc-$dirs-failed
  read_nix_style_files $@ | while read directive arguments_raw
  do
    diridx=$(( $diridx + 1 ))

    #printf -- "'$directive' '$arguments_raw'\n"
    # look for function or skip
    prep_dir_func $dirs || {
      r=$?; test $r -gt 1 || continue
      echo "prepare:$diridx" >>/tmp/uc-$dirs-failed
      error "Error preparing directive $directive $arguments_raw" $r
    }

    test -z "$idx" || {
      # Skip if diridx requested does not match
      test $diridx -lt $idx \
        && continue || test $idx -eq $diridx || return
    }

    # Evaluate before function
    test -n "$gen_eval" && {
      gen=$($gen_eval "$arguments")
      eval $gen && {
        info "evaluated $directive $arguments_raw"
        echo "exec:$diridx" >>/tmp/uc-$dirs-passed
        continue
      } || {
        error "Evaluation failure ($?): in $directive with '$arguments'"
        echo "eval:$diridx" >>/tmp/uc-$dirs-failed
        continue
      }
    } || noop

    # Execute directive
    $func_name $arguments && {
      debug "executed $directive $arguments_raw"
      echo "exec:$diridx" >>/tmp/uc-$dirs-passed
      continue
    } || { r=$?
      test "$RUN" = "stat" &&
        error "Status warning ($r): $directive '$arguments'" ||
        error "Failed ($r): $directive '$arguments'"
      echo "exec:$diridx" >>/tmp/uc-$dirs-failed
    }

  done

  test -n "$verbose" || verbose=true

  local ret=0

  trueish "$verbose" && {
    local failed=0 passed=0
    cln_out "/tmp/uc-$dirs-passed"; passed=$lines
    cln_out "/tmp/uc-$dirs-failed"; failed=$lines

    info "Passed: $passed, Failed: $failed"

    test $passed -gt 0 -a $failed -eq 0 && {
      note "All $passed directives passed"
    }
    test $passed -gt 0 || {
      error "No directive ran successfully"
      ret=1
    }
    test $failed -eq 0 || {
      warn "Failed $failed directives"
      ret=3
    }
  }

  return $ret
}

# Cleanup exec_dirs outputs after run
cln_out()
{
  test ! -s "$1" && lines=0 || {
    lines=$(wc -l $1 | awk '{print $1}')
    rm -f $1
    return 1
  }
  test ! -e "$1" || rm "$1"
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

# Use vc-gitdiff to check the file's checkout path and SHA1 object.
# Here, also allow file to exist in different repository.
diff_copy() # SCM-File Other-File
{
  case "$1" in
    "$UCONF*" )
        GITDIR=$UCONF vc_gitdiff "$1" "$2"
        return $?
      ;;
    * )
        GITDIR="$(vc_isgit "$1" || return 2)" \
          vc_gitdiff "$1" "$2"
        return $?
      ;;
  esac
  return 2
}

