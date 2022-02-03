#!/bin/sh


# Age in seconds
export _1MIN=60
export _5MIN=300
export _1HOUR=3600
export _1HOUR=3600
export _3HOUR=10800
export _6HOUR=64800
export _1DAY=86400
export _1WEEK=604800
export _1MONTH=$(( 31 * $_1DAY ))
export _1YEAR=$(( 365 * $_1DAY ))


# newer-than FILE SECONDS, filemtime must be greater-than Now - SECONDS
newer_than() # FILE SECONDS
{
  test -n "${1-}" || error "newer-than expected path" 1
  test -e "$1" || error "newer-than expected existing path" 1
  test -n "${2-}" || error "newer-than expected delta seconds argument" 1
  test -z "${3-}" || error "newer-than surplus arguments" 1

  # XXX: requires a bunch more functions
  #test $(date_epochsec "$2") -lt $(filemtime "$1")

  #fnmatch "@*" "$2" || set -- "$1" "-$2"
  test $(( $(date +%s) - $2 )) -lt $(filemtime $1) && return 0 || return 1
}

# older-than FILE SECONDS, filemtime must be less-than Now - SECONDS
older_than ()
{
  test -n "${1-}" || error "older-than expected path" 1
  test -e "$1" || error "older-than expected existing path" 1
  test -n "${2-}" || error "older-than expected delta seconds argument" 1
  test -z "${3-}" || error "older-than surplus arguments" 1

  #fnmatch "@*" "$2" || set -- "$1" "-$2"
  test $(( $(date +%s) - $2 )) -gt $(filemtime $1) && return 0 || return 1
}

# given timestamp, display a friendly human readable time-delta:
# X sec/min/hr/days/weeks/months/years ago
fmtdate_relative() # [ Previous-Timestamp | ""] [Delta] [suffix=" ago"]
{
  # Calculate delta based on now
  test -n "${2-}" || set -- "${1-}" "$(( $(date +%s) - $1 ))" "${3-}"

  # Set default suffix
  test -n "${3-}" -o -z "${datefmt_suffix-}" || set -- "${1-}" "$2" "$datefmt_suffix"

  test -n "${3-}" || set -- "${1-}" "$2" " ago"

  if test $2 -gt $_1YEAR
  then

    if test $2 -lt $(( $_1YEAR + $_1YEAR ))
    then
      printf -- "one year$3"
    else
      printf -- "$(( $2 / $_1YEAR )) years$3"
    fi
  else

    if test $2 -gt $_1MONTH
    then

      if test $2 -lt $(( $_1MONTH + $_1MONTH ))
      then
        printf -- "a month$3"
      else
        printf -- "$(( $2 / $_1MONTH )) months$3"
      fi
    else

      if test $2 -gt $_1WEEK
      then

        if test $2 -lt $(( $_1WEEK + $_1WEEK ))
        then
          printf -- "a week$3"
        else
          printf -- "$(( $2 / $_1WEEK )) weeks$3"
        fi
      else

        if test $2 -gt $_1DAY
        then

          if test $2 -lt $(( $_1DAY + $_1DAY ))
          then
            printf -- "a day$3"
          else
            printf -- "$(( $2 / $_1DAY )) days$3"
          fi
        else

          if test $2 -gt $_1HOUR
          then

            if test $2 -lt $(( $_1HOUR + $_1HOUR ))
            then
              printf -- "an hour$3"
            else
              printf -- "$(( $2 / $_1HOUR )) hours$3"
            fi
          else

            if test $2 -gt $_1MIN
            then

              if test $2 -lt $(( $_1MIN + $_1MIN ))
              then
                printf -- "a minute$3"
              else
                printf -- "$(( $2 / $_1MIN )) minutes$3"
              fi
            else

              printf -- "$2 seconds$3"

            fi
          fi
        fi
      fi
    fi
  fi
}

date_autores () # ~ <Date-Time-Spec>
{
  fnmatch "@*" "$1" && {
    true ${dateres:="minutes"}
    set -- "$(date_iso "${1:1}" minutes)"
  }
  echo "$1" | sed \
      -e 's/T00:00:00//' \
      -e 's/T00:00//' \
      -e 's/:00$//'
}

date_iso() # Ts [date|hours|minutes|seconds|ns]
{
  test -n "${2-}" || set -- "${1-}" date
  test -n "$1" && {
    $gdate -d @$1 --iso-8601=$2 || return $?
  } || {
    $gdate --iso-8601=$2 || return $?
  }
}

date_parse()
{
  test -n "${2-}" || set -- "$1" "%s"
  fnmatch "[0-9][0-9][0-9][0-9][0-9]*[0-9]" "$1" && {
    $gdate -d "@$1" +"$2"
    return $?
  } || {
    $gdate -d "$1" +"$2"
    return $?
  }
}

# Make ISO-8601 for given date or ts and remove all non-numeric chars except '-'
date_id () # <Datetime-Str>
{
  s= p= act=date_autores foreach_${foreach-"do"} "$@" | tr -d ':-' | tr 'T' '-'
}

# Parse compressed datetime spec (Y-M-DTHMs.ms+TZ) to ISO format
date_idp () # <Date-Id>
{
  foreach "$@" | $gsed -E \
      -e 's/^([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3T\4:\5:\6/' \
      -e 's/^([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2})/\1-\2-\3T\4:\5/' \
      -e 's/^([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})/\1-\2-\3T\4/' \
      -e 's/^([0-9]{4})([0-9]{2})([0-9]{2})/\1-\2-\3/' \
      -e 's/T([0-9]{2})([0-9]{2})([0-9]{2})$/T\1:\2:\3/' \
      -e 's/T([0-9]{2})([0-9]{2})/T\1:\2/' \
      -e 's/(-[0-9]{2}-[0-9]{2})([+-][0-9:]{2,5})$/\1T00\2/'
}

# Take compressed date-tstat format and parse to ISO-8601 again, local time
date_pstat ()
{
  test "$1" = "-" && echo "$1" || date_parse "$(date_idp "$1")"
}

#
