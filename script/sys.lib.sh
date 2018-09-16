#!/bin/sh

# Sys: lower level Sh helpers; dealing with vars, functions, and other shell
# idiosyncrasies.

sys_lib_load()
{
  test -n "$hostname" || hostname=$(hostname -s | tr 'A-Z' 'a-z')
  test -n "$uname" || uname="$(uname -s)"
}

# Error unless non-empty and true-ish value
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

# No error on empty or value unless matches trueish
not_trueish() # falsish or non-empty, ie. cannot anything other than unset or false
{
  test -n "$1" || return 0
  trueish "$1" && return 1 || return 0
}

create_ram_disk()
{
  test -n "$1" || error "Name expected" 1
  test -n "$2" || error "Size expected" 1
  test -z "$3" || error "Surplus arguments '$3'" 1

  case "$uname" in

    Darwin )
        local size=$(( $2 * 2048 ))
        diskutil erasevolume 'Case-sensitive HFS+' \
          "$1" `hdiutil attach -nomount ram://$size`
      ;;

      # Linux
      # mount -t tmpfs -o size=512m tmpfs /mnt/ramdisk

    * )
        error "Unsupported platform '$uname'" 1
      ;;

  esac
}

# Add an entry to PATH, see add-env-path-lookup for solution to other env vars
add_env_path() # Prepend-Value Append-Value
{
  test -e "$1" -o -e "$2" || {
    echo "No such file or directory '$*'" >&2
    return 1
  }
  test -n "$1" && {
    case "$PATH" in
      $1:* | *:$1 | *:$1:* ) ;;
      * ) export PATH=$1:$PATH ;;
    esac
  } || {
    test -n "$2" && {
      case "$PATH" in
        $2:* | *:$2 | *:$2:* ) ;;
        * ) export PATH=$PATH:$2 ;;
      esac
    }
  }
  # XXX: to export or not to launchctl
  #test "$uname" != "Darwin" || {
  #  launchctl setenv "$1" "$(eval echo "\$$1")" ||
  #    echo "Darwin setenv '$1' failed ($?)" >&2
  #}
}

# Add an entry to colon-separated paths, ie. PATH, CLASSPATH alike lookup paths
add_env_path_lookup() # Var-Name Prepend-Value Append-Value
{
  local val="$(eval echo "\$$1")"
  test -e "$2" -o -e "$3" || {
    echo "No such file or directory '$*'" >&2
    return 1
  }
  test -n "$2" && {
    case "$val" in
      $2:* | *:$2 | *:$2:* ) ;;
      * ) test -n "$val" && export $1=$2:$val || export $1=$2;;
    esac
  } || {
    test -n "$3" && {
      case "$val" in
        $3:* | *:$3 | *:$3:* ) ;;
        * ) test -n "$val" && export $1=$val:$3 || export $1=$3;;
      esac
    }
  }
}

remove_env_path_lookup()
{
  local newval="$( eval echo \"\$$1\" | tr ':' '\n' | while read oneval
    do
      test "$2" = "$oneval" -o "$(realpath "$2")" = "$(realpath "$oneval")" &&
        continue ;
      echo "$oneval" ;
    done | tr '\n' ':' | strip_last_nchars 1 )"

  export $1="$newval"
}

init_user_env()
{
  local key= value=
  for key in UCONFDIR HTDIR DCKR_VOL TMPDIR
  do
    value=$(eval echo \$$key)
    default=$(eval echo \$DEFAULT_$key)
    test -n "$value" || value=$default
    test -n "$value" || continue
    export $key=$value
    test -e "$value" || {
      echo "warning: path for $key does not exist: $value"
    }
  done
}

init_uconfdir_path()
{
  # Add path dirs in $UCONFDIR to $PATH
  local name
  for name in $uname Generic
  do
    local user_PATH=$UCONFDIR/path/$name
    if test -d "$user_PATH"
    then
      add_env_path $user_PATH
    fi
  done
}

std_utf8_en()
{
    export LANG="en_US.UTF-8"
    export LC_COLLATE="en_US.UTF-8"
    export LC_CTYPE="en_US.UTF-8"
    export LC_MESSAGES="en_US.UTF-8"
    export LC_MONETARY="en_US.UTF-8"
    export LC_NUMERIC="en_US.UTF-8"
    export LC_TIME="en_US.UTF-8"
    export LC_ALL=
}

update_env()
{
  test -n "$PYVENV" || {
    PYVENV=$(htd ispyvenv) || PYVENV=0
    export PYVENV
  }
}

activate()
{
  local update=false
  test -e "$HOME/.pyvenv/$1/bin/activate" && { update=true

    {  . "$HOME/.pyvenv/$1/bin/activate" &&
      export PYVENV=$HOME/.pyvenv/$1
    } || return $?
  }

  if $update ; then update_env ; fi
}

# This is called every time a PS1 PROMPT_COMMAND is executed, to get a simple
# string describing the host and perhaps CWD,PATH,PROJECT env. Especially
# when these are variants on the normal user profile, the normal name is
# ENV_NAME, which should be an ID describing ENV (or BASH_ENV, etc.). But
# additional formatting and IDs are added for
work_env()
{
  # Get name for shell profile
  test -z "$ENV_NAME" && {
    test -n "$hostname" || exit 110
    LENV="$hostname"
  } || {
    LENV="$ENV_NAME"
  }

  # Check for python v-env
  test "0" = "$PYVENV" || {
    LENV="$LENV,pyvenv"
  }
  printf -- "$LENV"
}

my_env_git_bash_prompt()
{
  LENV="$(work_env)"
  [[ $1 != 0 ]] && ERRMSG="[$1]" || ERRMSG=
  case "$TERM" in
    screen ) TITLE="\033k$(vc.sh screen)\033\\ " ;;
    ansi ) TITLE="\[\033]0;$(vc.sh screen)\007\]" ;;
    xterm* ) TITLE="\[\033]0;$(vc.sh screen)\007\]" ;;
  esac
  export PS1="$TITLE$RED$ERRMSG$NORMAL\n$MAGENTA\# $NORMAL$AOSEP\u$PAT\h$PSEP$($HOME/bin/vc.sh ps1)$LENV$APSEP\n$ISEP $TSEP\t $CYAN\$ $NORMAL"
}


# Update function for the GNU Screen title
# http://code-and-hacks.peculier.com/bash/setting-terminal-title-in-gnu-screen/
settitle()
{
  if [ -n "$STY" ] ; then         # We are in a screen session
    printf "\033k%s\033\\" "$@"
    screen -X eval "at \\# title $@" "shelltitle \"$@\""
  else
    printf "\033]0;%s\007" "$@"
  fi
}


get_uuid()
{
  test -e /proc/sys/kernel/random/uuid && {
    cat /proc/sys/kernel/random/uuid
    return 0
  }
  test -x $(which uuidgen) && {
    uuidgen
    return 0
  }
  stderr get-uuid "FIXME uuid required" 1
}

stderr()
{
  test -n "$1" && set -- base:$1 "$2" $3 || set -- $base "$2" $3
  echo "[$1] $2" >&2
  test -z "$3" || exit $3
}

calc() { echo "$*" | bc; }
hex2dec() { awk 'BEGIN { printf "%d\n",0x$1}'; }
dec2hex() { awk 'BEGIN { printf "%x\n",$1}'; }
mktar() { tar czf "${1%%/}.tar.gz" "${1%%/}/"; }
mkmine() { sudo chown -R ${USER} ${1:-.}; }
sendkey () {
  if [ $# -ne 0 ]; then
    echo '#' $*
    ssh $* 'cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_dsa.pub
  fi
}

if [ -z "$(which realpath)" ]
then # not perfect?
realpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#.}"
}
fi


# now reset terminal and clear space
# XXX: inteferes with any MOTD and loading python is quite costly
#if test -n "$(which clsp)"
#then
#  clsp
#fi
#ipython -c "import curses;v=curses.initscr();x=v.getmaxyx();curses.endwin();print x[0]*'\n'"
