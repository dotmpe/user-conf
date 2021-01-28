#!/bin/sh

set -e


# Load sh-lib
lib_load()
{
  local f_lib_load=
  test -n "$__load_lib" || local __load_lib=1
  test -n "$1" || set -- str-uc sys-uc os-uc std-uc src-uc match-uc
  while test -n "$1"
  do
    . $1.lib.sh load-ext
    f_lib_load=$(printf "${1}" | tr -Cs 'A-Za-z0-9_' '_')_load
    # again, func_exists is in sys.lib.sh. But inline here:
    type ${f_lib_load} 2> /dev/null 1> /dev/null && {
      ${f_lib_load}
    }
    shift
  done
}



# Main

case "$0" in "" ) ;; "-"* ) ;; * )
  test -n "$scriptname" || scriptname="$(basename "$0" .sh)"
  test -n "$verbosity" || verbosity=5
  test -z "$__load_lib" && lib_util_act="$1" || lib_util_act="load-ext"
  case "$lib_util_act" in

    load-ext ) ;; # External include, do nothing

    load )
        test -n "$scriptpath" || scriptpath="$(dirname "$0")/script"
        lib_load || {
          echo "Error loading $scriptname" 1>&2
          exit 1
        }
      ;;

    '' ) ;;

    * ) # Setup SCRIPTPATH and include other scripts
        echo "util-uc.lib: Ignored $scriptname argument(s) $0: $*" 1>&2
      ;;

  esac

;; esac

# Id: user-conf/0.0.1-dev script/util.lib.sh
# From: script-mpe/0.0.4-dev util.sh
# Sync: CONF:
