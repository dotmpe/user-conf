#!/usr/bin/env bash

## LINE directive

d_LINE_stat ()
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

d_LINE_update ()
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

#
