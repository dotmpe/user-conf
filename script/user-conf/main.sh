#!/usr/bin/env bash

scriptname=uc

# ----

def_func=uc__info


# Main

case "$0" in "" ) ;; "-*" ) ;; * )

  true "${uc_lib:="$(dirname "$(realpath "$0")")"}"
  . "$uc_lib"/lib.sh

  # Do something if script invoked as 'uc' or 'main'
  case "${base:=$(basename $0 .sh)}" in

    $scriptname | main )

        # invoke with function name first argument,
        cmd=${1-}
        test -n "$def_func" -a -z "$cmd" \
          && func=$def_func \
          || func=$(echo uc__$cmd | tr '-' '_')

        type $func >/dev/null 2>&1 && {
          test $# -eq 0 || shift 1
          test $human_out -eq 1 && {
            {
              $func "$@" || exit
            } 2>&1 | $UCONF/script/uc-colorize.sh >&2
          } || {
            $func "$@" || exit
          }
        } || {
          error "no command '$cmd' ($func)"
        }

      ;;

    * )
      echo "Not a frontend for '$base' ($scriptname)"

  esac

esac

# Id: U-c:script/user-conf/main.sh
