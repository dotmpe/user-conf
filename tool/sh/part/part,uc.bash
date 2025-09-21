uc-part ()
{
  while case "${1:?}" in
    ( --simple )
    ;;
      * ) false
    esac
  do shift
  done
  PATH=$UC_INC:$PATH . "${1:?}"
}
