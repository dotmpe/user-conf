class_gitdir_lib__load ()
{
  lib_require vc-uc || return
  ctx_class_types=${ctx_class_types-}${ctx_class_types+" "}GitDir
}

class.GitDir.load ()
{
  declare -gA class_GitDir__gitdirs
  declare -gA class_GitDir__basedirs
}

class.GitDir ()
{
  test $# -gt 0 || return 177
  test $# -gt 1 || set -- "$1" .toString
  local name=GitDir super_type=Class self super id=${1:?} method=$2
  shift 2
  self="class.$name $id "
  super="class.$super_type $id "

  case "$method" in
    ".$name" )
        test -d "$2" ||
            $LOG error : "No such dir" "$2" $? || return
        : "$(realpath "$2")"
        class_GitDir__basedirs[$id]=$_
        if_ok "$(vc_gitdir "$2")" || return
        class_GitDir__gitdirs[$id]=$_
        uc_fields_define vc-gitsubdir
        $super.$super_type "$1"
      ;;
    ".__$name" ) $super.__$super_type ;;

    .status ) false
        vc_fields_git_subdir
      ;;

    .clean ) false
        vc_fields_git_subdir
      ;;

    .class-context ) class.info-tree .tree ;;
    .class-info | .toString ) class.info ;;

    * ) $super$method "$@" ;;
  esac
}
