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

test ! -e "./node_modules/.bin/" || {
  export PATH=$(pwd)/node_modules/.bin:$PATH
}

test -n "$uname" || uname="$(uname -s)"
test ! -d $HOME/.conf/path/$uname || {
  export PATH=~/.conf/path/$uname:$PATH
}

test ! -d $HOME/.conf/path/Generic || {
  export PATH=~/.conf/path/Generic:$PATH
}

test -n "$DEFAULT_UCONFDIR" || {
    test -e "$HOME/.conf" && export DEFAULT_UCONFDIR=$HOME/.conf
}

init_user_env()
{
  local key= value=
  for key in UCONFDIR HTDIR
  do
    value=$(eval echo \$$key)
    default=$(eval echo \$DEFAULT_$key)
    test -n "$value" || value=$default
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


# Per host (override)
test -n "$hostname" || hostname=$(hostname -s | tr 'A-Z' 'a-z')
case "$hostname" in

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
        # undo Jenkins opt, unless EXIT_ON_ERROR is on
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

