
case "${xredo_target:?}" in

( @redo:env )
    declare -p | >&2 grep ' X\?REDO'
  ;;


 * ) return ${_E_next:-196}

esac

# Id: uc-build.redo-select.bash.do                                 ex:ft=bash:
