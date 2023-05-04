#!/usr/bin/env bash

# TODO: re-enable existing settings if line matches
# XXX: <keyword><sp> syntax does not help with shell script variables
# find a way to enable/disable #myshvar=foo


## LINE 'setting' helpers

# Print linenumer(s) that setting keyword occurs on
find_setting () # File Line Mode
{
  test -f "${1-}" || error "expected file path '$1'" 1
  test -n "${2-}" || error "expected config keyword" 1
  test -z "${4-}" || error "surplus arguments '$4'" 1

  local p="$(match_grep "$2")"

  lnr=$( case "${3:-1}" in

    1 )
        grep -q "^$p" $1 && {
          grep -n "^$p" $1 | cut -f 1 -d :
        }
      ;;

    2 )
        grep -q "^#$p" $1 && {
          grep -n "^#$p" $1 | cut -f 1 -d :
        }
      ;;
  esac | tail -n 1 )
  test -n "$lnr"
}

# return true if setting at line matches given setting
setting_matches()
{
  test -f "$1" || error "expected file path '$1'" 1
  test -n "$2" -a $2 -gt 0 || error "expected setting line number" 1
  test -n "$3" || error "expected setting line" 1
  test -z "$4" || error "surplus arguments '$3'" 1
  echo 'TODO: setting-matches '$1' "'$2'"'
}

enable_line () # ~ File Line-Nr
{
  test -f "${1-}" || error "expected file path '$1'" 1
  test -n "${2-}" || error "expected setting line number" 1
  test -z "${3-}" || error "surplus arguments '$3'" 1

  local tmpf=$(mktemp)
  {
    head -n $(( $2 - 1 )) "$1"
    head -n $2 "$1" | tail -n 1 | sed 's/#//'
    tail +$(( $2 + 1 )) "$1"
  } >"$tmpf"
  echo tmpf=$tmpf
  # cat "$tmpf"
  #rm "$tmpf"
}

disable_line()
{
  test -f "$1" || error "expected file path '$1'" 1
  test -n "$2" -a $2 -gt 0 || error "expected setting line number" 1
  test -z "$3" || error "surplus arguments '$3'" 1
  echo 'TODO: disable-line '$1:$2 >&2
  cmt="#$(get_lines $1:$2)"
  file_replace_at $1:$2 "$cmt"
}

add_setting () # ~ File Line
{
  test -f "${1-}" || error "expected file path '$1'" 1
  test -n "${2-}" || error "expected setting line" 1
  echo "$2" >>"$1"
}

# If setting is in file, enable that, or add line.
# Disable other setting(s) with matching keyword.
enable_setting () # ~ File Line
{
  test -f "${1-}" || error "expected file path '${1-}'" 1
  test -n "${2-}" || error "expected one ore more lines" 1
  test -z "${3-}" || error "surplus arguments '$3'" 1

  find_setting "$1" "$2" && return
  # shellcheck disable=SC2015
  find_setting "$1" "$2" 2 && {
    enable_line "$1" "$lnr" || return
  } || {
    add_setting "$1" "$2"
  }
}

# Sync: U-S:src/sh/lib/conf.lib.sh
