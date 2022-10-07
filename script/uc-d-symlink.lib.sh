#!/usr/bin/env bash

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
    case "${RUN:?}" in
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
      local target="$(readlink "$2")"
      test "$target" = "$1" && {
        return 0
      } || {
        case "${RUN:?}" in
          stat )
            log "Symlink should be updated '$2' -> {$target,$1}"
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
    case "${RUN:?}" in
      stat )
        return 2
        ;;
      update )
        ln -s $1 $2
        ;;
    esac
  }
}

d_SYMLINK_update ()
{
  d_SYMLINK "$@" || return $?
}

d_SYMLINK_stat ()
{
  d_SYMLINK "$@" || return $?
}

# Id: U-S
