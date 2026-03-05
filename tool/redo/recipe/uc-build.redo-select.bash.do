
case "${xredo_target:?}" in

( --help )
    >&2 cat <<EOM
This is --help at ${BASH_SOURCE[0]}

Usage:
      @redo:env - Typeset all (X)REDO variables
      @uc:build:env - Typeset all (x)redo variables
      @uc:build:handlers - Typeset current handlers array

EOM
    redo-always
  ;;

( @uc:build:handlers )
    declare -p uc_build_selects >&2
    redo-always
  ;;

( @uc:build:env )
    declare -p | >&2 grep -Ei ' uc[^=]+='
    redo-always
  ;;

( @redo:env )
    declare -p | >&2 grep ' X\?REDO'
    redo-always
  ;;


 * ) return ${_E_next:-196}

esac

# Id: uc-build.redo-select.bash.do                                 ex:ft=bash:
