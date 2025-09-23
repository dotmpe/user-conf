uc-symlink ()
{
  : id uc-symlink
  case "${1}" in
  ( --detect-argspec )
      :strword "${2}" &&
      :typearr "${2}" &&
      uconf-symlink --map "${2}" &&
      shift 2
    ;;
  ( --map ) UserConf-Directive-symlink-map "${@:2}"
      ;;
  ( -- ) UserConf-Directive-symlink-seq "${@:2}"
      ;;
    * ) UserConf-Directive-symlink "${@:2}"
  esac
}
declare -xf uc-symlink
