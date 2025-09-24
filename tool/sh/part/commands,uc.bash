uc-add ()
{
  : about '~ [<--options...>] <Name> ...'
  false TODO: include <Name> as source file
}
uc-copy ()
{
  : about '~ [<--options...>] <Name> <Dest...>'
  false
}
uc-symlink ()
{
  : about '~ [<--options...>] <Name> <Dest...>'
  : id uc-symlink
  case "${1}" in
  ( --detect-argspec )
      :strword "${2}" && {
        local known
        case "${known:=$(declare -p "$2")}" in
          ( "declare "* )
              #uconf-symlink --map "${2}"
              #uconf-symlink --seq "${2}"
            ;;
          ( "" ) unset known
            false
        esac ||
        case "${known:=$(declare -F "$2")}" in
          ( * ) ;;
          ( "" ) unset known
            false
        esac ||
        case "${known:=$(type -t "$2")}" in
          ( * ) ;;
          ( "" ) unset known
            false
        esac ||
        case "${known:=$(command -v "$2")}" in
          ( * ) ;;
          ( "" ) unset known
            false
        esac ||
        case "${known:=$(type -t "$2")}" in
          ( * ) unset known
            false
        esac
      } &&
      shift 2
    ;;
  ( --map ) UserConf-Directive-symlink-map "${@:2:1}" &&
      shift 2
    ;;
  ( --seq ) # XXX: either need runner access, or compile seq routine..
      UserConf-Directive-symlink-seq "${@:2:1}" &&
      shift 2
    ;;
  ( -- )
      local -a _uc_sl_pairs
      _uc_sl_pairs=( "${@:2}" )
      UserConf-Directive-symlink-seq _uc_sl_pairs
      return
    ;;
    * )
      UserConf-Directive-symlink "${@:1}"
      return
  esac
}
declare -xf uc-symlink
