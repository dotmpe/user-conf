uc-part ()
{
  while case "${1:?}" in
    ( --simple )
    ;;
      * ) false
    esac
  do shift
  done &&
  . "${1:?}"
}
