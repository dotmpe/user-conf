#!/bin/sh

set -e

# TODO: re-enable existing settings if line matches

## LINE 'setting' helpers

# use first word as keywords
get_setting_keyword()
{
  test -n "$1" || error "expected first word '$1'" 1
  firstword=$(echo "$1" | awk '{print $1}')
  test ${#firstword} -gt 2 || { error "keyword too small: $firstword"; return 4; }
  echo $firstword
}

# Print linenumer(s) that setting keyword occurs on
find_setting()
{
  test -f "$1" || error "expected file path '$1'" 1
  test -n "$2" || error "expected config keyword" 1
  test -z "$4" || error "surplus arguments '$4'" 1

  kw=$(get_setting_keyword "$2")

  test -z "$3" -o $3 -eq 1 -o $3 -eq 3 && {
    grep -q '^\<'$kw'\s' $1 && {
      grep -n '^\<'$kw'\s' $1 | cut -f 1 -d :
    }
  }
  test -z "$3" -o $3 -ge 2 && {
    grep -q '^#\<'$kw'\s' $1 && {
      grep -n '^#\<'$kw'\s' $1 | cut -f 1 -d :
    }
  }
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

enable_line()
{
  test -f "$1" || error "expected file path '$1'" 1
  test -n "$2" -a $2 -gt 0 || error "expected setting line number" 1
  test -z "$3" || error "surplus arguments '$3'" 1
  echo 'TODO: enable-line '$1' "'$2'"'
}

disable_line()
{
  test -f "$1" || error "expected file path '$1'" 1
  test -n "$2" -a $2 -gt 0 || error "expected setting line number" 1
  test -z "$3" || error "surplus arguments '$3'" 1
  echo 'TODO: disable-line '$1:$2
  cmt="#$(get_lines $1:$2)"
  file_replace_at $1:$2 "$cmt"
}

add_setting()
{
  test -f "$1" || error "expected file path '$1'" 1
  test -n "$3" || error "expected setting line" 1
  test -n "$2" || {
    set -- "$1" "$(find_setting "$1" "$3" 3 | sort | tail -n 1 )" "$3"
    note "add-setting: Set line to $2"
  }
  file_insert_at $1:$2 "$3"
}

# If setting is in file, enable that, or add line.
# Disable other setting(s) with matching keyword.
enable_setting()
{
  test -f "$1" || error "expected file path '$1'" 1
  test -n "$2" || error "expected one ore more lines" 1
  test -z "$3" || error "surplus arguments '$3'" 1

  # Find enabled setting, and disable
  find_setting "$1" "$2" 1 | while read lnr
  do
    disable_line $1 $lnr
  done

  # Add enabled line
  add_setting $1 "" "$2"
}

