case "${xredo_target}" in

( @config )
    redo-ifdone @host-env &&
    redo-ifchange .env
  ;;

( @env:* )
    : "${1#@env:}"
    : "${_//[:,.]/ }"
    declare -p $_ | redo-stamp
    #:pass "$(declare -p $_)" &&
    #redo-stamp <<< "${_}"
  ;;

( @host-env )
    redo-ifchange @env:PATH
  ;;

( .env )
    : "${U_C:=/src/local/user-conf+current}"
    echo "U_C=${U_C}"
    . "${U_C:?}"/tool/uc/part/uc-assert.directive-handlers.bash
    declare -p uc_build_selects
    echo PATH=\$PATH:${U_C:?}/tool/redo/recipe
  ;;

( * )
    #>&2 echo "${xredo_build_select}: Unknown target $1"
    return 196
  ;;

esac &&

redo-ifchange "${BASH_SOURCE[0]}"

# ex:ft=bash:
