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
  us_fail $_E_GAE --\
    std_argv eq 2 $# "Newer-than argc expected" --\
    assert_ n "${1-}" "Newer-than expected path" --\
    assert_ e "${1-}" "Newer-than expected existing path" --\
    assert_ n "${2-}" "Newer-than expected delta seconds argument" || return

  # XXX: requires a bunch more functions
  #test $(date_epochsec "$2") -lt $(filemtime "$1")

  fnmatch "@*" "$2" || set -- "$1" "-$2"
  test $(( $(date +%s) - $2 )) -lt $(filemtime $1) && return 0 || return 1
}

# older-than FILE SECONDS, filemtime must be less-than Now - SECONDS
older_than ()
{
  us_fail $_E_GAE --\
    std_argv eq 2 $# "Older-than argc expected" --\
    assert_ n "${1-}" "Older-than expected path" --\
    assert_ e "${1-}" "Older-than expected existing path" --\
    assert_ n "${2-}" "Older-than expected delta seconds argument" || return

  fnmatch "@*" "$2" || set -- "$1" "-$2"
  test $(( $(date +%s) - $2 )) -gt $(filemtime $1) && return 0 || return 1
}

#
