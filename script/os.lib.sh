#!/bin/sh

test -n "$PREFIX" || PREFIX=$HOME


filesize()
{
  case "$uname" in
    Darwin )
      stat -L -f '%z' "$1" || return 1
      ;;
    Linux )
      stat -L -c '%s' "$1" || return 1
      ;;
  esac
}

filemtime()
{
  case "$uname" in
    Darwin )
      stat -L -f '%m' "$1" || return 1
      ;;
    Linux )
        err "TODO linux" 254
      stat -L -c '%s' "$1" || return 1
      ;;
  esac
}

