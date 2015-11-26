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
  test -n "$1" || set -- "." "origin"
  test -d "$1" || err "vc-gitremote expected dir argument" 1
  test -n "$2" || err "vc-gitremote expected remote name" 1
  test -z "$3" || err "vc-gitremote surplus arguments" 1

  cd "$(vc_gitdir "$1")"
  git config --get remote.$2.url
}

vc_gitdiff()
{
  test -n "$1" || err "vc-gitdiff expected src" 1
  test -n "$2" || err "vc-gitdiff expected trgt" 1
  test -z "$3" || err "vc-gitdiff surplus arguments" 1
  test -n "$GITDIR" || err "vc-gitdiff expected GITDIR env" 1
  test -d "$GITDIR" || err "vc-gitdiff GITDIR env is not a dir" 1

  target_sha1="$(git hash-object "$2")"
  co_path="$(cd $GITDIR;git rev-list --objects --all | grep "^$target_sha1" | cut -d ' ' -f 2)"
  test -n "$co_path" -a "$1" = "$GITDIR/$co_path" && {
    return 0
  } || {
    error "unknown state for path $2"
    return 1
  }
}

