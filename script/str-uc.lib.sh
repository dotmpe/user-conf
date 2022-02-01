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

# Derive: U-S:src/sh/lib/str.lib.sh
