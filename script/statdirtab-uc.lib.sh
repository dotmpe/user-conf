
## Multi-file tab files in statusdir

statdirtab_uc_lib__load ()
{
  lib_require class-uc || return # statusdir
  ctx_class_types=${ctx_class_types-}${ctx_class_types+" "}StatDirTab
}

statdirtab_uc_lib__init ()
{
  true
}


class_StatDirTab__load ()
{
  Class__static_type[StatDirTab]=StatDirTab:StatTab
}

class_StatDirTab_ () # :Class ~ <ID> .<METHOD> <ARGS...>
#   .StatDirTab <Basename> <TabClass>                 - constructor
{
  case "${call:?}" in

    .basenames ) : "${Class__instances[$id]}" && : "${_% *}" && echo "${_// /$'\n'}" ;;
    .tabclass ) : "${Class__instances[$id]}" && echo "${_//* }" ;;
    .directories )
        # metadir_basedirs
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

    ( * ) return ${_E_next:?} ;;

  esac
  return ${_E_done:?}
}
