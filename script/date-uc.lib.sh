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

# Given a timestamp, display a friendly human readable time-delta:
# X sec/min/hr/days/weeks/months/years ago. This is not very precise, as it
# only displays a single unit and no fractions. But it is sufficient for a lot
# of purposes. See fmtdate_relative_f
fmtdate_relative () # ~ [ Previous-Timestamp | ""] [Delta] [suffix=" ago"]
{
  # Calculate delta based on now
  test -n "${2-}" || set -- "${1-}" "$(( $(date +%s) - $1 ))" ${3-}

  # Set default suffix
  test $# -gt 2 || set -- "${1-}" "$2" " ${datefmt_suffix:-"ago"}"

  if test $2 -gt $_1YEAR
  then

    if test $2 -lt $(( $_1YEAR + $_1YEAR ))
    then
      test ${datefmt_human_readable:-1} -eq 1 &&
        printf -- "one year$3" || printf -- "1y$3"
    else
      printf -- "$(( $2 / $_1YEAR )) years$3"
    fi
  else

    if test $2 -gt $_1MONTH
    then

      if test $2 -lt $(( $_1MONTH + $_1MONTH ))
      then
        test ${datefmt_human_readable:-1} -eq 1 &&
          printf -- "a month$3" || printf -- "1mo$3"
      else
        printf -- "$(( $2 / $_1MONTH )) months$3"
      fi
    else

      if test $2 -gt $_1WEEK
      then

        if test $2 -lt $(( $_1WEEK + $_1WEEK ))
        then
          test ${datefmt_human_readable:-1} -eq 1 &&
            printf -- "a week$3" ||
            printf -- "1w$3"
        else
          test ${datefmt_human_readable:-1} -eq 1 &&
            printf -- "$(( $2 / $_1WEEK )) weeks$3" ||
            printf -- "$(( $2 / $_1WEEK ))w$3"
        fi
      else

        if test $2 -gt $_1DAY
        then

          if test $2 -lt $(( $_1DAY + $_1DAY ))
          then
            test ${datefmt_human_readable:-1} -eq 1 &&
              printf -- "a day$3" ||
              printf -- "1d$3"
          else
            test ${datefmt_human_readable:-1} -eq 1 &&
              printf -- "$(( $2 / $_1DAY )) days$3" ||
              printf -- "$(( $2 / $_1DAY ))d$3"
          fi
        else

          if test $2 -gt $_1HOUR
          then

            if test $2 -lt $(( $_1HOUR + $_1HOUR ))
            then
              test ${datefmt_human_readable:-1} -eq 1 &&
                printf -- "an hour$3" ||
                printf -- "1h$3"
            else
              test ${datefmt_human_readable:-1} -eq 1 &&
                printf -- "$(( $2 / $_1HOUR )) hours$3" ||
                printf -- "$(( $2 / $_1HOUR ))h$3"
            fi
          else

            if test $2 -gt $_1MIN
            then

              if test $2 -lt $(( $_1MIN + $_1MIN ))
              then
                test ${datefmt_human_readable:-1} -eq 1 &&
                  printf -- "a minute$3" ||
                  printf -- "1min$3"
              else
                test ${datefmt_human_readable:-1} -eq 1 &&
                  printf -- "$(( $2 / $_1MIN )) minutes$3" ||
                  printf -- "$(( $2 / $_1MIN ))min$3"
              fi
            else

              test ${datefmt_human_readable:-1} -eq 1 &&
                printf -- "$2 seconds$3" ||
                printf -- "$2s$3"

            fi
          fi
        fi
      fi
    fi
  fi
}

# XXX: want more resolution for fmtdate_relative.
# Also printing several orders together. But not a lot of customization.
fmtdate_relative_f ()
{
  test ${2//.*} -gt 0 && {
    # Seconds

    test ${2//.*} -gt 60 && {
      # Minutes

      test ${2//.*} -gt 3600 && {
        # Hours

        test ${2//.*} -gt 86400 && {
          # Days

          test ${2//.*} -gt 604800 && {
            # Weeks

            test ${2//.*} -gt 31536000 && {
              # Years

              printf '%.0f years, %.0f weeks, %.0f days, %.0f hours%s' \
                "$(echo "$2 / 31536000"|bc)" \
                  "$(echo "$2 % 31536000 / 604800"|bc)" \
                    "$(echo "$2 % 31536000 % 604800 / 86400"|bc)" \
                      "$(echo "$2 % 31536000 % 604800 % 86400 / 3600"|bc)" "$3"

            } || {
              printf '%.0f weeks, %.0f days, %.0f hours, %.0f minutes%s' \
                "$(echo "$2 / 604800"|bc)" \
                  "$(echo "$2 % 604800 / 86400"|bc)" \
                    "$(echo "$2 % 604800 % 86400 / 3600"|bc)" \
                      "$(echo "$2 % 604800 % 86400 % 3600 / 60"|bc)" "$3"
            }
          } || {
            printf '%.0f days, %.0f hours, %.0f minute, %.0f seconds%s' \
              "$(echo "$2 / 86400"|bc)" \
                "$(echo "$2 % 86400 / 3600"|bc)" \
                  "$(echo "$2 % 86400 % 3600 / 60"|bc)" \
                    "$(echo "$2 % 86400 % 3600 % 60"|bc)" "$3"
          }
        } || {
          printf '%.0f hours, %.0f minutes, %.0f seconds%s' \
            "$(echo "$2 / 3600"|bc)" \
              "$(echo "$2 % 3600 / 60"|bc)" \
                "$(echo "$2 % 3600 % 60"|bc)" "$3"
        }
      } || {
        printf '%.0f minutes, %.0f seconds%s' \
          "$(echo "$2 / 60"|bc)" "$(echo "$2 % 60"|bc)" "$3"
      }
    } || {
      printf '%.3f seconds%s' "$2" "$3"
    }

  } || {
    # Miliseconds
    set -- "$1" "0$(echo "$2 * 1000" | bc)" $3
    test ${2//.*} -gt 0 && {
      printf '%.3f miliseconds%s' "$2" "$3"
    } || {
      # Microseconds
      set -- "$1" "0$(echo "$2 * 1000" | bc)" $3
      test ${2//.*} -gt 0 && {
        printf '%.3f microseconds%s' "$2" "$3"
      } || {
        # Nanoseconds
        set -- "$1" "0$(echo "$2 * 1000" | bc)" $3
        printf '%.3f nanoseconds%s' "$2" "$3"
      }
    }
  }
}

time_fmt_abbrev ()
{
   sed ' s/,//g
          s/ nanoseconds\?/ns/
          s/ microseconds\?/us/
          s/ miliseconds\?/ms/
          s/ seconds\?/s/
          s/ minutes\?/m/
          s/ hours\?/h/
          s/ days\?/d/
          s/ weeks\?/w/
          s/ months\?/mo/
          s/ years\?/y/'
}

# Output date at required resolution
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
