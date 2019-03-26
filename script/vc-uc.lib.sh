#!/bin/sh

set -e


vc_gitdir()
{
  test -n "$1" || set -- "."
  test -e "$1" -a -d "$1" || set -- "$(dirname "$1")"
  test -d "$1" || error "vc-gitdir expected dir argument: '$1'" 1
  test -z "$2" || error "vc-gitdir surplus arguments: '$2'" 1

  local pwd="$(pwd)"
  cd "$1"
  repo=$(git rev-parse --git-dir 2>/dev/null)
  while fnmatch "*/.git/modules*" "$repo"
  do repo="$(dirname "$repo")" ; done
  test -n "$repo" || return 1
  echo "$repo"
  #repo="$(git rev-parse --show-toplevel)"
  #echo $repo/.git
  cd "$pwd"
}

# See if path is in GIT checkout
vc_isgit()
{
  test -e "$1" || error "vc-isgit expected path argument: '$1'" 1
  test -z "$2" || error "vc-isgit surplus arguments: '$2'" 1
  test -d "$1" || {
    set -- "$(dirname "$1")"
  }
  ( cd "$1" && go_to_dir_with .git || return 1 )
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

# Given COPY src and trgt file from user-conf repo,
# see if target path is of a known version for src-path in repo,
# and that its the currently checked out version.
vc_gitdiff()
{
  test -n "$1" || error "vc-gitdiff expected src" 1
  test -n "$2" || error "vc-gitdiff expected trgt" 1
  test -z "$3" || error "vc-gitdiff surplus arguments" 1
  test -n "$GITDIR" || error "vc-gitdiff expected GITDIR env" 1
  test -d "$GITDIR" || error "vc-gitdiff GITDIR env is not a dir" 1

  target_sha1="$(git hash-object "$2")"
  co_path="$(cd $GITDIR;git rev-list --objects --all | grep "^$target_sha1" | cut -d ' ' -f 2)"
  test -n "$co_path" -a "$1" = "$GITDIR/$co_path" && {
    # known state, file can be safely replaced
    test "$target_sha1" = "$(git hash-object "$1")" \
      && return 0 \
      || {
        return 1
      }
  } || {
    return 2
  }
}

# Sync: CONF:
