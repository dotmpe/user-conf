#!/bin/sh


scriptname=uc

test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"

. "$uc_lib"/lib.sh



# ----

def_func=c_stat


# Main

case "$0" in "" ) ;; "-*" ) ;; * )

  # Do something if script invoked as 'uc'
  base=$(basename $0 .sh)
  case "$base" in

    $scriptname | main )

        # invoke with function name first argument,
        cmd=$1
        test -n "$def_func" -a -z "$cmd" \
          && func=$def_func \
          || func=$(echo c_$cmd | tr '-' '_')

        type $func &>/dev/null && {
          shift 1
          #load
          $func "$@"
        } || {
          #load
          error "executing $cmd ($func)"
        }

      ;;

    * )
      echo "Not a frontend for $base ($scriptname)"

  esac

esac


