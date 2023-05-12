
## Multi-file tab files in statusdir

statdirtab_uc_lib__load ()
{
  lib_require ctx-class # statusdir
  : "${ctx_class_types:="${ctx_class_types-}${ctx_class_types+" "}StatDirTab"}"
}

statdirtab_uc_lib__init ()
{
  true
}


class.StatDirTab () # ~ <ID> .<METHOD> <ARGS...>
#   .StatDirTab <Basename> <TabClass>                 - constructor
{
  test $# -gt 0 || return 177
  test $# -gt 1 || set -- $1 .toString
  local name=StatDirTab super_type=Class self super id=$1 method=$2
  shift 2
  self="class.$name $id "
  super="class.$super_type $id "

  case "$method" in
    .$name ) $super.$super_type "$@" ;;
    .__$name ) $super.__$super_type ;;

    .basenames ) : "${Class__instances[$id]}" && : "${_% *}" && echo "${_// /$'\n'}" ;;
    .tabclass ) : "${Class__instances[$id]}" && echo "${_//* }" ;;
    .directories )
        user_lookup_path ~/.local/statusdir/index -- .meta/tabs .meta/stat/index .local/statusdir/index .statusdir/index
      ;;
    .names )
        local fp filepaths
        mapfile -t filepaths <<< "$($self.paths)"
        for fp in "${filepaths[@]}"
        do basename "$fp"; done
      ;;
    .paths )
        local dir names dirs
        mapfile -t names <<< "$($self.basenames)"
        mapfile -t dirs <<< "$($self.directories)"
        for dir in "${dirs[@]}"
        do
          for name in "${names[@]}"
          do
            set -- $dir/$name*
            test $# -gt 0 || continue
            printf '%s\n' "$@"
          done
        done
      ;;

    .class-context ) class.tree .tree ;;
    .class-info | .toString ) class.info ;;

    * ) $super$method "$@" ;;
  esac
}

