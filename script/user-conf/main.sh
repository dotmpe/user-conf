#!/bin/sh


scriptname=uc

test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"

. "$uc_lib"/lib.sh


stdio_type 0
stdio_type 1
stdio_type 2

# setup default options
test -n "$choice_interactive" || {
  case "$stdio_1_type" in t )
    choice_interactive=true ;;
  esac
}

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


