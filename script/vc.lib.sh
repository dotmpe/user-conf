#!/bin/sh

set -e


vc_gitdir()
{
  test -n "$1" || set -- "."
  test -d "$1" || err "vc-gitdir expected dir argument" 1
  test -z "$2" || err "vc-gitdir surplus arguments" 1
  test -d "$1/.git" && {
    echo "$1/.git"
  } || {
    test "$1" = "." || cd $1
    git rev-parse --git-dir 2>/dev/null
  }
}

vc_gitremote()
{
  test -n "$1" || set -- "."
  test -d "$1" || err "vc-gitremote expected dir argument" 1
  test -n "$2" || err "vc-gitremote expected remote name" 1
  test -z "$3" || err "vc-gitremote surplus arguments" 1

  cd "$(vc_gitdir "$1")"
  git config --get remote.$2.url
}

