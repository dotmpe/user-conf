: "${_E_nsc:=64}" # Command name-context conflict @draft
: "${_E_nss:=65}" # Generic namespace failure @draft
: "${_E_nsl:=66}" # Name lookup failure @draft
: "${_E_nsk:=67}"  # No such key (by static or builtin tag, ie. flag, option) @draft

: "${keep_going:=0}"

uc-status ()
{
  : about 'Experimental helper to abstract return status handling'
  : param '~ [<--options...>]'
  : id uc-status

  local fail=0 utd=1 stat=${UC_STATUS:?}
  [[ ${_E_continue:?} -eq $stat || ${_E_retry:?} -eq $stat ]] &&
    fail=1 ||
    [[ ${_E_next:?} -eq $stat ]] && utd=0 ||
    return $stat

  while (($#))
  do
    case "${1}" in
    ( --changed ) ! ((utd)) ;;
    ( --continue )
        [[ ${stat:?} -eq ${_E_continue:?} ]] ||
        [[ ${stat:?} -eq ${_E_next:?} ]] || {
          [[ ${stat:?} -eq ${_E_retry:?} ]] && ((keep_going))
        }
      ;;
    ( --failed ) ((fail)) ;;
    ( --next ) [[ ${stat:?} -eq ${_E_next:?} ]] ;;
    ( --nochange ) ((utd)) && ! ((fail)) ;;
    ( --ok ) ! ((fail)) ;;
    ( --pass ) ! ((fail)) || return ${stat:?} ;;
      * ) :stat ${_E_nss:?}
    esac &&
    shift
  done
}

uc-status-new ()
{
  UC_STATUS=$?
  uc-status "$@"
}

declare -xf uc-status
