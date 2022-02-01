#!/usr/bin/env bash

version=0.2.0 # user-conf

scriptname=uc

# ----

uc__version ()
{
  echo "$version"
}

uc__usage ()
{
  echo "$scriptname info"
  echo "$scriptname initialize"
  echo "$scriptname install [IDX]"
  echo "$scriptname stat [IDX]"
  echo "$scriptname update [IDX]"
  echo "$scriptname add"
  echo "$scriptname test"
  echo "$scriptname commit"
  echo "$scriptname status"
  echo "$scriptname report"
  echo
  echo "$scriptname version"
  echo "$scriptname help"
}

uc__help ()
{
  uc__usage
  echo "See doc/user-conf.rst"
}

def_func=uc__info


# Main

case "$0" in "" ) ;; "-*" ) ;; * )

  true "${uc_lib:="$(dirname "$(realpath -- "$0")")"}"
  . "$uc_lib"/lib.sh

  # Do something if script invoked as 'uc' or 'main'
  case "${base:=$(basename -- $0 .sh)}" in

    $scriptname | main )

        # invoke with function name first argument,
        cmd=${1-}
        test -n "$def_func" -a -z "$cmd" \
          && func=$def_func \
          || func=$(echo uc__$cmd | tr '-' '_')

        debug "Starting main function '$func'..."
        type $func >/dev/null 2>&1 && {
          test $# -eq 0 || shift 1
          test $human_out -eq 1 && {
            {
              $func "$@" || exit $?
            } 2>&1 | {
              $sh_lib/uc-colorize.sh >&2
            }
            exit $?

          } || {
            $func "$@"
            exit $?
          }
        } || {
          error "no command '$cmd' ($func)"
        }

      ;;

    * )
      echo "Not a frontend for '$base' ($scriptname)"

  esac

esac

# Id: user-conf/0.2.0 script/user-conf/main.sh
