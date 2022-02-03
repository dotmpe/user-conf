#!/usr/bin/env bash
# Created: 2015-09-21

test -n "${sh_lib:-}" || sh_lib="$(dirname $uc_lib)"

true "${LOG:?Require log handler}"

. ${sh_lib}/../tools/u-c/env.sh
INIT_LOG=$LOG

. "$sh_lib"/shell-uc.lib.sh
shell_uc_lib_load

test $IS_BASH_SH -eq 1 && {
  set -o nounset -o pipefail

  # This triggers
  #/etc/profile.d/uc-profile.sh: /usr/share/bashdb/bashdb-main.inc: No such file or directory
  #/etc/profile.d/uc-profile.sh: warning: cannot start debugger; debugging mode disabled
  # at t460s but only sometimes.
  #shopt -s extdebug

  # setting errtrace allows our ERR trap handler to be propagated to functions,
  #  expansions and subshells
  set -o errtrace # same as -E

  # Leave a path of line-numbers in array BASH_LINENO
  # thate tells where functions where called
  set -o functrace # same as -T

  # trap ERR to provide an error handler whenever a command exits nonzero
  #  this is a more verbose version of set -o errexit
  . "$sh_lib"/bash-uc.lib.sh
  trap 'bash_uc_errexit' ERR

} || {

  $LOG warn "" "Non-Bash TO-TEST"
}

test $IS_DASH_SH -eq 1 && {
  set -o nounset
}

log_key=$USER@$(hostname):$scriptname:${1-} # FIXME why is default not working

# load and init lib parts
. "$sh_lib"/argv-uc.lib.sh
. "$sh_lib"/std-uc.lib.sh
. "$sh_lib"/str-uc.lib.sh
. "$sh_lib"/src-uc.lib.sh
. "$sh_lib"/ansi-uc.lib.sh
. "$sh_lib"/match-uc.lib.sh
. "$sh_lib"/os-uc.lib.sh
. "$sh_lib"/date-uc.lib.sh
. "$sh_lib"/vc-uc.lib.sh
. "$sh_lib"/sys-uc.lib.sh
. "$sh_lib"/stdlog-uc.lib.sh
#. "$sh_lib"/syslog-uc.lib.sh
. "$sh_lib"/conf-uc.lib.sh

sys_uc_lib_load
std_uc_lib_load
os_uc_lib_load
ansi_uc_lib_load
stdlog_uc_lib_load
#syslog_uc_lib_load

case "${TERM-}" in
  "" ) ;;
  dumb ) ;;
  * ) true "${COLORIZE:=1}" ;;
esac

std_uc_lib_init
ansi_uc_lib_init

test -n "${HOME-}" || {
  test -n "${username:-}" && HOME=/home/$username || error "no user dir set" 100
}
test -e "$HOME" || error "no user dir" 100

# All boxes
#true "${OS_NAME:="$(uname -o)"}"           # Eg. 'GNU/Linux'
true "${OS_KERNEL:="$(uname -s)"}"          # Eg. 'Linux', also 'OS name'
true "${OS_RELEASE:="$(uname -r)"}"         # Version nr
true "${HARDWARE_NAME:="$(uname -m)"}"   # Eg. x86_64
#true "${HARDWARE_PLATFORM:="$(uname -i)"}" # Eg. x86_64
true "${HARDWARE_PROCESSOR:="$(uname -p)"}" # Idem. to machine-type on x86

if test -e /etc/os-release
then
  _os_dist () { sed 's/^/DIST_/g' /etc/os-release; }
  eval $(_os_dist)     # Eg. DIST_ID=debian or ubuntu
                       # And DIST_NAME='Debian GNU/Linux'
                       #  or DIST_NAME=Ubuntu
else
  DIST_ID=
  DIST_NAME=
  DIST_VERSION=
  DIST_VERSION_ID=
fi

if test "$OS_KERNEL" = "Darwin" # BSD/Darwin
then
  OS_NAME=
  HARDWARE_PLATFORM=
else
  true "${OS_NAME:="$(uname -o)"}"
  true "${HARDWARE_PLATFORM:="$(uname -i)"}"
fi

test -n "${hostname-}" -a -n "${domain-}" || {
  test -e $HOME/.statusdir/tree/domain &&  {
    hostname=$(cat $HOME/.statusdir/tree/domain | sed 's/^\([^\.]*\)\..*$/\1/g')
    domain=$(cat $HOME/.statusdir/tree/domain | sed 's/^[^\.]*\.//g')
  } || {
    hostname="$(hostname -s | tr 'A-Z.' 'a-z-' | tr -s '-' '-' )"
    domain="$(hostname -f | cut -c$(( ${#hostname} + 2 ))-)"
  }
}
hostdom=$hostname-${domain:-local}
# XXX: vol_id=$disk_id-$part_id

true "${username:=$(whoami)}"

test -n "${human_out:-}" || { test -t 1 && human_out=1 || human_out=0; }

test -n "${TMP-}" -a -w "${TMP-}" || {
	test -w /tmp && TMP=/tmp || {
		TMP=$HOME/.local/tmp
		mkdir -p $TMP
	}
}

uc_cache_ttl=3600


# Functions

# User-config holds directives for current env/host, make a copy to
# install/$hostname.u-c of the first existing path in
# boilerplate{,-{$machine,$uname,$domain}}.u-c
uc__initialize ()
{
  get_conf
  test -d "${UCONF-}" || error "No UCONF found" 1
  test "$hostname.$domain" = "$(hostname)" || {
    echo "$hostname.$domain" > $HOME/.domain
  }
  cd "$UCONF"
  local conf=install/$hostname.u-c \
    local_conf=local.u-c

  test -e "install/$local_conf" ||
    ln -s $(basename $conf) install/$local_conf

  test ! -e "$conf" || {
    note "Already initialized: $conf"
    return
  }

  local tpl=
  for tag in $hostname $HARDWARE_NAME-$HARDWARE_PROCESSOR $HARDWARE_PROCESSOR \
    $HARDWARE_NAME $OS_KERNEL-$OS_RELEASE $OS_KERNEL $OS_RELEASE ""
  do
    tpl=install/boilerplate${tag:+-}${tag}.u-c
    test ! -e "$tpl" || {
      cp -v $UCONF/$tpl $UCONF/$conf
      note "Initialized $hostname from $tag boilerplate"
      break
    }
  done
}

uc__init()
{
  uc__initialize "$@"
}

uc__install()
{
  local conf=
  req_conf || return
  exec_dirs install "$1" $conf || return $?
}

# Update host from provision and config directives
uc__update()
{
  local conf=
  req_conf || return
  exec_dirs update "${1-}" $conf || return $?
}

# Compare host with provision and config directives
# 1:diridx
uc__stat()
{
  local conf=
  req_conf || return
  exec_dirs stat "${1-}" $conf || return $?
}

# Add a new path to config (COPY directive only)
# XXX: looks like bashisms
uc__add()
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
  req_conf || return

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
        error "expected directory or symlink '$2' for '$1'"
        return 1
      }
    }
  } || {
    test -d "$(dirname $2)" || {
      error "no parent dir for target path '$2' for '$1'"
      return 1
    }
  }
  # remove broken link first
  test ! -h "$2" -o -e "$2" || {
    log "Broken symlink '$2' for '$1'"
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


uc_sudo_path_target ()
{
  { test ! -r "$2" -o ! -r "$(dirname "$2")";} && {
    test ${warn_on_sudo:-1} -eq 0 || {
      warn "Setting sudo to read '$2' (for '$1')"
    }
    sudor="sudo -i "
  }

  { test ! -w "$2" -o ! -w "$(dirname "$2")";} && {
    test ${warn_on_sudo:-1} -eq 0 || {
      warn "Setting sudo to write '$2' (for '$1')"
    }
    sudow="sudo -i "
  }
}

## Copy directive

# TODO: make copy update permission bits
d_COPY() # SCM-Src-File Host-Target-File
{
  local sudor= sudow= sudod=
  test -e "$1" && set -- "$(realpath "$1")" "$2" "$1"
  test -f "$1" || {
    error "not a file: $1 ($(pwd))"
    return 1
  }
  uc_sudo_path_target "$@"

  ${sudor}test -e "$2" -a -d "$2" && {
      copy_target="$(normalize_relative "$2/$(basename "$1")")"
      debug "Expanding '$2' to '$copy_target'"
      set -- "$1" "$copy_target"
  } || true

  ${sudor}test -e "$2" && {
    # Existing copy

    stat=0
    ${sudor}test -f "$2" && {
      diff_copy "$1" "$2" || { stat=2
        ${sudor}diff -q "$1" "$2" && {
           note "Changes resolved but uncommitted for 'COPY \"$1\" \"$2\"'"
           return
        }
        # Check existing COPY version
        test $STD_INTERACTIVE -eq 1 && {
          # XXX: lmfao. shut up
          #${sudow}test -w /dev/tty || {
            sudo chmod go+rw /dev/tty || return; # }
          # XXX: FIXME without TTY vimdiff won't work here
          ${sudow}vimdiff "$1" "$2" </dev/tty >/dev/tty && {
            ${sudor}diff -q "$1" "$2" && stat=0 || return 1
          } ||
            warn "Interactive Diff still non-zero ($?)"
        } || return 1
      }
    } || {
      ${sudor}test ! -f "$2" && {
        error "Copy target path already exists and not a file '$2'"
        return 2
      }
    }

    case "$stat" in
      0 )
          std_info "Up to date with '$1' at '$2'"
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
          ${sudow}cp "$1" "$2" || {
            log "Copy to $2 failed"
            return 1
          }
        ;;
    esac

  } || {

    # New copy
    test -w "$(dirname "$2")" || {
      test ${warn_on_sudo:-1} -eq 0 || {
        warn "Setting sudo to access '$(dirname $2)' (for '$1')"
      }
      sudod="sudo "
    }
    case "$RUN" in
      stat )
        log "Missing copy of '$1' at '$2'"
        return 1
        ;;
      update )
        ${sudod}cp "$1" "$2" &&
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

d_WEB () # URL TARGET-PATH
{
  test -n "$1" || error "expected url for $diridx:WEB" 1
  test -n "$2" || error "expected target path for $dirix:WEB <$1>" 1
  test $# -lt 4 || error "surplus params: '$4'" 1

  test -d "$2" -o \( ! -e "$2" -a -d "$(dirname "$2")" \) -o -f "$2" \
    || error "target must be existing directory or a (new) file in one: $2 "\
"(for $diridx:WEB)" 1

  test -d "$2" && {
      test "$(basename "$1")" != "$1" \
        || error "cannot get target basename from URL '$1', please provide "\
"full path (for $diridx:WEB)" 1
      set -- "$1" "$2/$(basename $1 .git)" "$3"
  }

  case "$RUN" in update ) PREF= ;; stat ) PREF="echo '** DRY-RUN **: '" ;; esac

  tmpf=$TMP/$(uuidgen)
  curl -LsS "$1" -o $tmpf || {
    error "Unable to fetch '$1' to $tmpf"
    return 1
  }
  test -e "$tmpf" || {
    error "Failed to fetch '$1' to $tmpf"
    return 1
  }

  test -e "$2" && {
    diff -bq $2 $tmpf && {
      std_info "Up to date with web at $2"
    } || {
      ${PREF}cp $tmpf $2 || {
        error "Failed to copy $tmpf to '$1'"
        return 1
      }
      note "Updated $2 from $1"
      case "$RUN" in update ) ;; * ) return 1 ;; esac
    }
  } || {
    ${PREF}cp $tmpf $2 || {
       error "Failed to copy $tmpf to '$1'"
      return 1
    }
    note "New path $2 from $1"
    case "$RUN" in update ) ;; * ) return 1 ;; esac
  }
}

d_WEB_update () # URL TARGET-PATH
{
  RUN=update d_WEB "$@" || return $?
}

d_WEB_stat () # URL TARGET-PATH
{
  RUN=stat d_WEB "$@" || return $?
}


## GIT directive

d_GIT()
{
  test -n "$1" || error "expected url for $diridx:GIT" 1
  test -n "$2" || error "expected target path for $diridx:GIT <$1>" 1
  test -n "${3-}" || set -- "$1" "$2" "origin" "${4-}" "${5-}"
  test -n "${4-}" || set -- "$1" "$2" "$3" "master" "${5-}"
  test -n "${5-}" || set -- "$1" "$2" "$3" "$4" "clone"
  test $# -lt 6 || error "surplus params: '$6'" 1

  test -d "$2" -o \( ! -e "$2" -a -d "$(dirname "$2")" \) \
    || error "target must be existing directory or a new name in one: $2" 1

  test ! -e "$2/.git" || {
    req_git_remote "$1" "$2" "$3" || return $?
  }

  test ! -e "$2" -a -d "$(dirname "$2")" || {
    test -e "$2/.git" && req_git_remote "$1" "$2" "$3" || {
      test "$(basename "$1" .git)" != "$1" \
        || error "cannot get target basename from GIT <$1>, please provide "\
"full check path (for $diridx:GIT)" 1
      set -- "$1" "$2/$(basename $1 .git)" "$3" "$4" "$5"
    }
  }

  req_git_age

  case "$RUN" in update ) PREF= ;; stat ) PREF="echo '** DRY-RUN **: '" ;; esac

  case "$5" in

    clone )
      test -e "$2/.git" && { ( cd $2

        git diff --quiet && {
          GITDIR="$(vc_gitdir)"
          test -d "$GITDIR" || error "cannot determine gitdir at <$2>" 1
          { { test -e $GITDIR/FETCH_HEAD || {
              std_info "No FETCH_HEAD in <$2>" ; false; }
            } && {
              newer_than $GITDIR/FETCH_HEAD $GIT_AGE
            }
          } || {
            std_info "Fetching <$2> branch '$4' from remote '$3'"
            test "$RUN" = stat && {
              git fetch --dry-run -q $3 $4 || true
            } || {
              git fetch -q $3 $4 2>/dev/null || {
                error "Error fetching remote $3 for $2"; return 1; }
            }
          }
          debug "Comparing <$2> branch '$4' with remote '$3' ref"
          git diff --quiet && {
            git show-ref --quiet $3/$4 || git fetch $3
            git show-ref --quiet $3/$4 || {
              warn "No ref '$3/$4'"
              return 1
            }
            git diff --quiet $3/$4..HEAD && {
              test "$4" = "master" \
                && std_info "Checkout $2 clean and up-to-date" \
                || std_info "Checkout $2 clean and up-to-date at branch $4"
            } || {

              # Try to merge remote, but only not if bare. NOTE: need to keep .git
              # at remote URLs for to denote bare, strip .../.git from checkout.
              fnmatch "*/.git " "$1" && return

              note "Checkout <$2> clean but not in sync with '$3' at branch '$4'"
              false # break to co/pull
            }
          } || {
            test -e ".git/refs/heads/$4" || {
              ${PREF}git checkout -b $4 -t $3/$4 || return
            }
            ${PREF}git checkout $4 -- || return
            ${PREF}git pull $3 $4 || return
            test ! -e .gitmodules || { # XXX: assumes always need modules
              git submodule update --init
            }
            test "$4" = "master" \
              && note "Updated <$2> from remote '$3'" \
              || note "Updated <$2> from remote '$3' (at branch $4)"
            case "$RUN" in update ) ;; * ) return 1 ;; esac
          }
        } || {
          test "$4" = "master" \
            && warn "Checkout at <$2> looks dirty" \
            || warn "Checkout of '$4' at <$2> looks dirty"
          return 1
        }
        ) || return

      } || {
        test "$4" = "master" \
          && note "Checkout missing at <$2>" \
          || note "Checkout of '$4' missing at <$2>"
        ${PREF}git $5 "$1" "$2" --origin $3 --branch $4
        case "$RUN" in update ) return $? ;; * ) return 1 ;; esac
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

d_LINE_stat()
{
  test -f "$1" || error "expected file path '$1'" 1
  test -n "$2" || error "expected one ore more lines" 1

  eval "set -- $arguments_raw"
  file=$1
  shift 1
  for line in "$@"
  do
    find_setting "$file" "$line" || {
      error "Missing '$line' in '$file'"
      return 1
    }
  done
}

d_LINE_update()
{
  test -f "$1" || error "expected file path '$1'" 1
  test -n "$2" || error "expected one ore more lines" 1

  eval "set -- $arguments_raw"
  file=$1
  shift 1
  for line in "$@"
  do
    std_info "Looking for '$line' in '$file'"
    test -w "$file" && {
      enable_setting $file "$line" || return
    } || {
      local bn="$(basename "$file")"
      sudo mv "$file" "/tmp/$bn"
      sudo chown $USER "/tmp/$bn"
      enable_setting "/tmp/$bn" "$line" || return
      sudo cp "/tmp/$bn" "$file"
      rm "/tmp/$bn"
    }
  done
}

# TODO: add sudo for both FILE and DIR directives
d_DIR_stat ()
{
  local dir
  for dir in $@
  do test -d "$dir" || return
  done
}

d_DIR_update ()
{
  local dir
  for dir in $@
  do test -d "$dir" || mkdir -p "$dir"
  done
}

d_FILE_stat ()
{
  local file
  for file in $@
  do test -f "$file" || return
  done
}

d_FILE_update ()
{
  local file
  for file in $@
  do test -f "$file" || touch "$file"
  done
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
  test $# -lt 3 || error "AGE surplus params: '$3'" 1
  test $# -eq 1 && set -- "CACHE" "$1"
  set -- "$(echo $1 | tr 'a-z' 'A-Z')" "$2"
  case "$1" in
    GIT )
      printf "export GIT_AGE=$2"
      std_info "Max. GIT remote ref age to $2 seconds"
    ;;
    * )
      printf "export %s_AGE=%s" "$@"
    ;;
  esac
}


## Installers

# print missing/mismatching packages
d_INSTALL_list_APT()
{
  out=$TMP/bin-apt-installed.list
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
  out=$TMP/bin-pip-installed.list
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

# get conf env: the u-c file for this host and all its includes
get_conf ()
{
  test -n "${conf-}" ||
    for UCONF in $PWD ${UCONFDIR:-$HOME/.conf}
    do
      test -e $UCONF/Ucfile &&
        conf=$UCONF/Ucfile || {
        test -e $UCONF/install/local.u-c && {
          conf=$UCONF/install/local.u-c
        } || {
          test -e $UCONF/install/$hostname.u-c && {
            conf=$UCONF/install/$hostname.u-c
          }
        }
      }
      test -n "${conf-}" && break
    done

  # Put UCONFDIR into static user env / profile to preempt and use single
  # user-config dir [TODO-A]
  true "${UCONF:="${UCONFDIR-"$(dirname "$(realpath "$conf")")"}"}"
  true "${UCONFDIR:="$UCONF"}"
}

req_conf ()
{
  get_conf
  test -e $conf || error "no such user-config $conf" 1
  conf="$(echo $conf $(verbose=false exec_dirs include $conf))"
  test -n "$conf" && note "Using U-c '$conf'" || {
      warn "No U-c found"
      return 1
    }
}

# Private helper for exec_dirs
_prep_dir_func () # Action
{
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
        std_info "Nothing to install for #$diridx $packager"
        return 1
      }
      ;;

    # provision/config directives support stat or update
    COPY | SYMLINK | GIT | WEB | LINE | DIR )
      case $1 in install) return 1 ;; esac
      func_name="d_${directive}_$1"
      arguments="$(eval echo "$arguments_raw")"
      ;;

    ENV | AGE | SH | SH_RAW | BASH ) # Update env; always updates
      gen_eval="d_${directive}_exec"
      ;;

    INCLUDE )
      case $1 in include) ;; * ) return ;; esac
      arguments="$(eval echo "$arguments_raw")"
      echo "$arguments"
      ;;

    * ) error "Unknown directive $directive" 1 ;;

  esac
}

# Set cache and result files
uc_reset_report () # Index
{
  test -z "${1-}" && {
    results=$TMP/$$-uc-$hostdom.list
    uc_cache=$HOME/.statusdir/cache/uc-$hostdom.list
  } || {
    results=$TMP/$$-uc-$hostdom-$1.list
    uc_cache=$HOME/.statusdir/cache/uc-$hostdom-$1.list
  }
  test -d ~/.statusdir/cache || mkdir -vp ~/.statusdir/cache
}

# Move last result to cache location
uc_commit_report ()
{
  test -e "$results" ||
    error "uc:commit:report Expected results file <$results>" 1
  cat "$results" >"$uc_cache"
  rm "$results"
}

# Load last results
uc_report ()
{
  test -n "${uc_cache-}" || uc_reset_report
  test -e "$uc_cache" || {
    error "No results"
    passed= failed= directives=
    return 1
  }

  passed="$(grep '^ok ' "$uc_cache" | count_lines )"
  failed="$(grep -v '^ok ' "$uc_cache" | count_lines )"
  directives="$(count_lines "$uc_cache")"
}

idx_spec ()
{
  local start len
  set -- $(echo "$*" | tr ',' ' ')
  while test $# -gt 0
  do
    debug "spec '$1'"
    case "$1" in
      *"-"* ) seq ${1//-/ } ;;
      *"+"* ) start=${1//+*/}; len=${1//*+/};
        seq $start $(( $start + $len )) ;;
      * ) echo "$1" ;;
    esac
    shift
  done | tr '\n' ' '
}

# Dynamic Eval of directives from u-c file, pref-dir-func maps each directive
# to a function with name ``d_<DIRECTIVE>_<function>()``.
# Use index argument to select single line to execute
exec_dirs () # Action Directive-Index read-args..
{
  test $# -ge 3 || return 98
  local action=$1 func_name= arguments= diridx=0 idx=${2-} idxs
  test -z "$idx" || {
    note "Requested selective execution of directives '$idx'"
    idxs="$(idx_spec "$idx")"
    debug "Resolved index-spec to '$idxs'"
  }

  uc_reset_report $2
  shift 2
  read_nix_style_files $@ | while read directive arguments_raw
  #OLDIFS="$IFS"
  #IFS=$'\n'; for directive_line in $( read_nix_style_files $@ | lines )
  do
    #IFS="$OLDIFS"
    #directive="${directive_line/ *}"
    #arguments_raw="${directive_line:$(( ${#directive} + 1 ))}"
    diridx=$(( $diridx + 1 ))

    #printf -- "'$directive' '$arguments_raw'\n"
    # look for function or skip
    _prep_dir_func $action || {
      r=$?; test $r -gt 1 || continue
      echo "err:$r prepare:$diridx $directive $arguments_raw" >>"$results"
      error "Error preparing directive $directive $arguments_raw" $r
    }

    test -z "$idx" || {
      # Skip if diridx requested does not match
      fnmatch "* $diridx *" " $idxs " || continue
      # XXX: cleanup
      #test $diridx -lt $idx \
      #  && continue || test $idx -eq $diridx || return
    }

    # Evaluate before function
    test -n "$gen_eval" && {
      gen=$($gen_eval "$arguments")
      local r
      eval $gen && {
        debug "evaluated $directive $arguments_raw"
        echo "ok eval:$diridx $directive $arguments_raw" >>"$results"
        continue
      } || { r=$?
        error "Evaluation failure ($r): in $directive with '$arguments'"
        echo "fail:$r eval:$diridx $directive $arguments_raw" >>"$results"
        continue
      }
    } || true

    # Execute directive
    local r
    $func_name $arguments && {
      debug "executed $directive $arguments_raw"
      echo "ok exec:$diridx $directive $arguments_raw" >>"$results"
      continue
    } || { r=$?
      test "${RUN:-}" = "stat" &&
        std_info "Status warning ($r): $directive '$arguments'" ||
        debug "Failed ($r): $directive '$arguments'"
      echo "fail:$r exec:$diridx $directive $arguments_raw" >>"$results"
    }

  done

  local ret=0

  uc_commit_report
  uc__status
}

# Get or set default GIT age
req_git_age()
{
  # XXX AGE is eval'd in sequence, seems convenient for some meta dirs
  #grep -qi '^AGE\ GIT\ ' && {
  #  age_expr=$(echo $(grep -i '^AGE\ GIT\ ') | cut -d ' ' -f 3)
  #  # TODO: parse some expression for age: 1h 5min 5m etc.
  #  GIT_AGE="$age_expr"
  #} || true

  test -n "$GIT_AGE" || {
    GIT_AGE=$_5MIN
    debug "Max. GIT remote ref age set to $GIT_AGE seconds"
  }
}

req_git_remote()
{
  test -n "$1" || error "expected url" 1
  test -d "$2" || error "expected checkout dir '$2'" 1
  test -n "$3" || set -- "$1" "$2" "origin"
  test $# -lt 4 || error "req-git-remote surplus arguments" 1

  GITDIR="$(vc_gitdir "$2")"
  url="$(cd "$2"; git config remote.${3}.url)"
  test -n "$url" && {
    test "$url" = "$1" -o "$url" = "$1/.git" || {
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

uc__commit()
{
  test "$(pwd)" = "$UCONF" || cd $UCONF
  git diff --quiet && {
    git commit -m "At $hostname" || return
    git pull || return
    git push || return
  } || {
    error "dir looks dirty"
  }
}

# Use vc-gitdiff to check the file's checkout path and SHA1 object.
# Here, also allow file to exist in different repository.
diff_copy() # SCM-File Other-File
{
  GITDIR="$UCONF" vc_gitdiff "$1" "$2"
}

uc__status ()
{
  local ret=0
  uc_report

  test $verbosity -ge 5 && {
    cat "$uc_cache"
  } || {
    test $verbosity -ge 3 && {
      grep -v '^ok ' "$uc_cache"
    }
  }

  std_info "Passed: $passed, Failed: $failed"
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

  { test -e "$uc_cache" && newer_than "$uc_cache" $uc_cache_ttl
  } || {
    warn "Results are stale (>${uc_cache_ttl}s)"
    ret=4
  }

  return $ret
}

# Quietly test for valid result
uc__test ()
{
  test -n "${uc_cache-}" || uc_reset_report
  test -e "$uc_cache" && newer_than "$uc_cache" $uc_cache_ttl || return
  uc_report
  test $failed -eq 0 -a $passed -gt 0
}

# Report on last result
uc__report ()
{
  uc_report

  test $human_out -eq 1 && {
    local verbosity=6
    std_info "Host-domain: $hostdom"
    std_info "Passed: $passed"
    std_info "Failed: $failed"
    std_info "Total: $directives"
  } || {
    echo "hostdom=$hostdom"
    echo "passed=$passed"
    echo "failed=$failed"
    echo "total=$directives"
  }
}

# Report on config and location
uc__env ()
{
  local conf=
  test $human_out -eq 1 && {
    local verbosity=6
      std_info "U-c scripts: $uc_lib"
      std_info "Sh script libs: $sh_lib"
  } || {
      echo "uc_lib=$uc_lib"
      echo "sh_lib=$sh_lib"
  }

  req_conf || return 0

  config_name="$(test "$( basename $conf )" = "local" &&
    basename $conf || basename $(realpath $conf) )"

  test $human_out -eq 1 && {
    local verbosity=6
    std_info "UConf: $UCONF"
    std_info "Config: $conf"
    std_info "Config-Name: $config_name"
  } || {
    echo "UCONF=$UCONF"
    echo "conf=$conf"
    echo "config_name=$config_name"
  }
}

# Report on config and state
uc__info ()
{
  uc__env &&
  uc__report
}

# XXX: consolidate

: "${DOMAIN:=}"
: "${HOST:="$(hostname --long)"}"

: "${UC_CONFIG_NAME:="local $DOMAIN $HOST-$USER $hostname-$USER host $HOST $hostname user $USER generic default"}"

: "${UC_CONFIG_INSTALL_EXT:="u-c"}"
: "${UC_DEFAULT_GROUPS:="etc"}"

# Lookup file anywhere in UCONF repo, based on its filename and location.
uc__config () # ~ [NAME][.EXT] [--] [GROUP [GROUP...]]
{
  argv_uc__argc :uc:config $# ge 1 || return
  local name ext groups
  fnmatch "*.*" "$1" && {
    # EXT is the last '.'-separated part of the name
    ext="${1##*.}"
    # NAME is minus last EXT
    name="${1%.*}"
  } || name="$1"
  shift

  test "${1-}" = '--' || set -- "$@" ${UC_DEFAULT_GROUPS}
  test "${1-}" = "--" && shift
  set -- $name "$@"
  $LOG debug :uc:config "Looking for config at" "$*"

  test -n "${ext-}" || {

    # Look-up exts for most specific NAME with exts
    ext=`uc__resolve_env EXT $(reverse "$@")` || {
      $LOG error :uc:config "Cannot find EXT" "" 1
    }
  }

  $LOG note :uc:config "Looking for config file" "$name.$ext"

  while test $# -gt 0
  do
    local path lname

    for path in `uc__resolve_path $(reverse "$@") | while IFS= read -r path; \
      do \
        first=true; \
        while $first || test "$path" != "./" -a "$path" != "//"; \
        do \
          first=false; \
          echo "$path"; \
          path=$(dirname "$path")/; \
        done; \
      done || true`
    do
      for lname in `uc__resolve_env "$@" || echo "$1"`
      do
        test -e "$UCONF/$path/$lname.$ext" || continue
        break 2
      done
    done
    shift

    test -n "${lname-}" -a -n "${path-}" -a -e "$UCONF/${path-}/${lname-}.$ext" && {
      echo "$UCONF/$path$lname.$ext"
      break
    } || {
      test $# -gt 0 || return
    }
  done
}

## Lookup actual file(s) named 'FILE' in a location specified by GROUP's.
uc__resolve () # ~ [[...GROUP] GROUP] FILE[.EXT]
{
  true
}

## Lookup actual directory named by GROUP's.
uc__resolve_path () # ~ GROUP [GROUP...]
{
  test $# -gt 0 || return 64

  $LOG note :resolve-path "Lookup existing path for groups" "$*"
  {
    local last=false
    while test $# -gt 0
    do
      local name=
      for name in $(uc__resolve_env $(reverse "$@") || true)
      do
        test -d "$name" || continue
        break
      done
      test -n "$name" || name="$1"
      shift
      test -d "$name" || return
      cd "$name"
      echo "$name"
    done
  } | {
    tr -s "$IFS" '/'; echo;
  }
}

## Lookup ``UC_{<GROUP>_,}<VAR>``-keyed value in shell env.
uc__resolve_env () # ~ VAR [GROUP [GROUP...]]
{
  test $# -gt 0 || return 64

  local v var="$1" uc_resolve_prefix
  uc_resolve_prefix="${UC_RESOLVE_PREFIX:-"Uc Config "}"
  shift
  # Reverse arguments Bash-style
  set -- $(for (( i=$#;i>0;i-- ));do echo "${!i}"; done)
  $LOG note :resolve-env "Lookup env var" "NAME=$var GROUPS=$*"

  # Loop until either varref exists or no args left
  while true
  do
    varref="$uc_resolve_prefix$(test $# -eq 0 || printf '%s ' "$@")$var"
    v="$(printf '%s' "$varref" | tr -c 'A-Za-z0-9_' '_')"
    v="${v^^}"
    #echo varref=$varref varname=$v >&2
    v="${!v-}"
    test -n "$v" -o $# -eq 0 && break
    shift
  done
  # Abort or print
  test -n "${v-}" || return
  printf -- '%s' "$v"
}

uc__has_config ()
{
  uc__config >&2
}

uc__user_has_config ()
{
  true
}

reverse ()
{
  for (( i=$#;i>0;i-- ))
  do echo "${!i}"
  done
}

#
