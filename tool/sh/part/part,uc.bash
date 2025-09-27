uc-part ()
{
  local all=0
  while case "${1:?}" in
    ( --simple )
    ;;
    ( --all ) all=1
    ;;
      * ) false
    esac
  do shift
  done &&
  ((all)) && {
    local nameref
    for nameref
    do
      . "${nameref:?}" || return
    done
  } || {
    . "${1:?}"
  }
}
