#!/bin/sh


# Age in seconds
_5MIN=300
_1HOUR=3600
_3HOUR=10800
_6HOUR=64800
_1DAY=86400
_1WEEK=604800


# newer-than FILE SECONDS, filemtime must be greater-than Now - SECONDS
newer_than() # FILE SECONDS
{
  test -n "${1-}" || error "newer-than expected path" 1
  test -e "$1" || error "newer-than expected existing path" 1
  test -n "${2-}" || error "newer-than expected delta seconds argument" 1
  test -z "${3-}" || error "newer-than surplus arguments" 1

  # XXX: requires a bunch more functions
  #test $(date_epochsec "$2") -lt $(filemtime "$1")

  fnmatch "@*" "$2" || set -- "$1" "-$2"
  test $(( $(date +%s) - $2 )) -lt $(filemtime $1) && return 0 || return 1
}

# older-than FILE SECONDS, filemtime must be less-than Now - SECONDS
older_than ()
{
  test -n "${1-}" || error "older-than expected path" 1
  test -e "$1" || error "older-than expected existing path" 1
  test -n "${2-}" || error "older-than expected delta seconds argument" 1
  test -z "${3-}" || error "older-than surplus arguments" 1

  fnmatch "@*" "$2" || set -- "$1" "-$2"
  test $(( $(date +%s) - $2 )) -gt $(filemtime $1) && return 0 || return 1
}

#
