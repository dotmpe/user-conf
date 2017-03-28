#!/bin/bash

# keep current shell settings and keep quiet during script
test -n "$shopts" || shopts=$-
set +x || printf ""
set -e || printf ""


# set PATH so it includes user's private bin if it exists
test ! -e "$HOME/bin/" || {
  export PATH=$PATH:$HOME/bin
}

test ! -e "$HOME/.local/bin/" || {
  export PATH=$PATH:$HOME/.local/bin
}

test ! -e "$HOME/.basher" || {

  export BASHER_SHELL=bash
  export BASHER_ROOT=$HOME/.basher
  export PATH="$BASHER_ROOT/bin:$BASHER_ROOT/cellar/bin:$PATH"
  source "$BASHER_ROOT/completions/basher.bash"
  for f in $(command ls "$BASHER_ROOT/cellar/completions/bash"); do source
    "$BASHER_ROOT/cellar/completions/bash/$f"; done
}

test ! -e "$HOME/.htd-tools/bin" || {
  export HTDTOOLS_ROOT=$HOME/.htd-tools
  export PATH="$HTDTOOLS_ROOT/bin:$HTDTOOLS_ROOT/cellar:$PATH"
}

test ! -e "./node_modules/.bin/" || {
  export PATH=$(pwd)/node_modules/.bin:$PATH
}

test -n "$uname" || uname="$(uname -s)"
test ! -d $HOME/.conf/path/$uname || {
  export PATH=~/.conf/path/$uname:$PATH
}

test ! -d $HOME/.conf/path/Generic || {
  export PATH=~/.conf/path/Generic:$PATH
test -n "$DEFAULT_HTDIR" || {
	test -e "$HOME/public_html" && export DEFAULT_HTDIR=$HOME/public_html
}

test -n "$DEFAULT_UCONFDIR" || {
    test -e "$HOME/.conf" && export DEFAULT_UCONFDIR=$HOME/.conf
}

test -n "$DEFAULT_DCKR_VOL" || {
  for top_name in -mpe -brix -local
  do
    for local_name in -$(hostname -s | tr 'A-Z' 'a-z') ""
    do
      test -e "/srv/docker$local_name$top_name" && {
        export DEFAULT_DCKR_VOL=/srv/docker$local_name$top_name
        break 2
      }
    done
  done
}

test -n "$DEFAULT_TMPDIR" || {
  test -e "/tmp" && export DEFAULT_TMPDIR=/tmp
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
      PATH=$user_PATH:$PATH
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

# Per host (override)
test -n "$hostname" || hostname=$(hostname -s | tr 'A-Z' 'a-z')
case "$hostname" in

  sandbox* )
    export HTDIR=$HOME/htdocs
    export HTD_GIT_REMOTE=dotmpe

    init_user_env
    init_uconfdir_path

    case $CS in dark )
          export VIM_THEME=murphy
          export VIM_THEME=mustang
          export VIM_AIRLINE_THEME=ubaryd
        ;;
      light )
          export VIM_THEME=sienna
          export VIM_AIRLINE_THEME=sol
        ;;
      * )
          export VIM_THEME=murphy
        ;;
    esac

    ;;

  * )
      echo "Using generic bash/env"

      init_user_env
      init_uconfdir_path

    ;;

esac

# Restore shell -e opt
case "$shopts"

  in *e* )
      test "$EXIT_ON_ERROR" = "false" -o "$EXIT_ON_ERROR" = "0" && {
        # undo parent opt, unless EXIT_ON_ERROR is on
        echo "[$0] Important: Shell will NOT exit on error (EXIT_ON_ERROR=$EXIT_ON_ERROR)"
        set +e
      } || {
        echo "[$0] Note: Shell will exit on error (EXIT_ON_ERROR=$EXIT_ON_ERROR)"
        set -e
      }
    ;;

  * )
      # Turn off again
      set +e
    ;;

esac

# Restore shell -x opt
case "$shopts" in
  *x* )
    case "$DEBUG" in
      [Ff]alse|0|off|'' )
          # undo verbosity by Jenkins, unless DEBUG is explicitly on
          set +x
        ;;
      * ) 
          echo "[$0] Shell debug on (DEBUG=$DEBUG)"
          set -x
        ;;
    esac
  ;;
esac

