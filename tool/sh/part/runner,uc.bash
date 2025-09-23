uc-runner ()
{
  case "${1:?}" in
  ( apply ) (
        : param '~ ~ <Uc-profile-part>'
        local uc_idx=0
        uc-runner load-dsl &&
        "${2:?}" || :failp "At ${2@Q}"
      )
    ;;
  ( load-dsl )
      . "userconf,dsl,uc.bash"
      for uc_dsl in "${!userconf_dsl[@]}"
      do
        : "${uc_dsl}"
        :% ${_} "
          [[ \$1 == -- ]] && {
            uc-runner run-seq ${_} \"\${@:2}\"
            return
          }
          uc-runner run ${_} \"\${@}\" "
      done
    ;;
  ( load-dir )
      :typefun UserConf-Directive-${2} ||
        uc-part --simple ${2},directive,uc.bash ||
          :failp "E$? while loading ${1@Q} source"
    ;;
  ( run )
      uc-runner load-dir "${2}" &&
      ((uc_idx+=1)) &&
      "UserConf-Directive-${2}" "${@:3}"
    ;;
  ( run-seq )
      uc-runner load-dir "${2}" &&
      local dir="UserConf-Directive-${2}" &&
      local -n dir_argc=uconf_dir_${2,,}_argc &&
      shift 2 &&
      while [[ $# -gt 0 ]]
      do
        ((uc_idx+=1)) &&
        "$dir" "${@:${dir_argc:-1}}" ||
          :failp "At ${uc_idx}: $dir: sequence '${@:${dir_argc:-1}}'" || return
        shift ${dir_argc-}
      done
    ;;
    * ) false || :failp "? $FUNCNAME ${*@Q}"
  esac
}
