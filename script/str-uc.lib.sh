#!/bin/sh


# Use this to easily matching strings based on glob pettern, without
# adding a Bash dependency (keep it vanilla Bourne-style shell).
fnmatch () # PATTERN STRING
{
  case "$2" in ( $1 ) return 0 ;; ( * ) return 1 ;; esac
}

## Put each line into lookup table (with Awk), print on first occurence only
#
# To remove duplicate lines in input, without sorting (unlike uniq -u).
remove_dupes() # <line> ... ~
{
  awk '!a[$0]++'
}
#
# mkid STR '-' '\.\\\/:_'
mkid () # ~ Str Extra-Chars Substitute-Char
{
  #test -n "$1" || error "mkid argument expected" 1
  local s="${2-}" c="${3-}"
  # Use empty c if given explicitly, else default
  test $# -gt 2 || c='\.\\\/:_'
  test -n "$s" || s=-
  test -n "${upper-}" && {
    test $upper -eq 1 && {
      id=$(printf -- "%s" "$1" | tr -sc '[:alnum:]'"$c$s" "$s" | tr 'a-z' 'A-Z')
    } || {
      id=$(printf -- "%s" "$1" | tr -sc '[:alnum:]'"$c$s" "$s" | tr 'A-Z' 'a-z')
    }
  } || {
    id=$(printf -- "%s" "$1" | tr -sc '[:alnum:]'"$c$s" "$s" )
  }
}
# Sync-Sh: BIN:str-htd.lib.sh


# Normalize whitespace (replace newlines, tabs, subseq. spaces)
normalize_ws()
{
  test -n "${1-}" || set -- '\n\t '
  tr -s "$1" ' ' # | sed 's/\ *$//'
}


# Derive: U-S:src/sh/lib/str.lib.sh
