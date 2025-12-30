: "${keep_going:=0}"

uc-status ()
{
  : about 'Experimental helper to abstract return status handling'
  : param '~ [<--options...>]'
  : id uc-status

  local fail=0 utd=1 stat=${uc_status:?}
  [[ ${_E_continue:?} -eq $stat || ${_E_retry:?} -eq $stat ]] &&
  fail=1 || {
    [[ ${_E_next:?} -eq $stat ]] && utd=0 || return $stat
  }

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
  uc_status=$?
  uc-status "$@"
}

declare -xf uc-status
