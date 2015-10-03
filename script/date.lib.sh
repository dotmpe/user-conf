#!/bin/sh


# Age in seconds
_5MIN=300
_1HOUR=3600
_3HOUR=10800
_6HOUR=64800
_1DAY=86400
_1WEEK=604800


younger_than()
{
  test $(( $(date +%s) - $2 )) -lt $(filemtime $1) && return 0 || return 1
}

older_than()
{
  test $(( $(date +%s) - $2 )) -gt $(filemtime $1) && return 0 || return 1
}


