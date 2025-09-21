uc-runner ()
{
  case "${1:?}" in
  ( apply ) (
        uc_idx=0
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
            uc-runner run-seq UserConf-Directive-${_} \"\${@:2}\"
            return
          }
          uc-runner run UserConf-Directive-${_} \"\${@}\" "
      done
    ;;
  ( load-dir )
      Sh-Fun-Exists UserConf-Directive-${2} ||
        uc-part ${2},directive,uc.bash ||
          :failp "E$? while loading ${1@Q} source"
    ;;
  ( run )
      uc-runner load-dir "${2}" &&
      ((uc_idx+=1)) &&
      "${@:2}"
    ;;
  ( run-seq )
      uc-runner load-dir "${2}" &&
      dir=$2 &&
      shift 2 &&
      for s
      do
        ((uc_idx+=1)) &&
        "$dir" "${s}" ||
          :failp "At ${uc_idx}: $dir: ${s@Q}" || return
      done
    ;;
    * ) false || :failp "? ${1@Q}"
  esac
}

