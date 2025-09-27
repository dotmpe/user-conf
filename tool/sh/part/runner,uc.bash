uc-runner ()
{
  case "${1:?}" in
  ( apply ) (
        : param '~ ~ <Uc-profile-part>'
        local uc_idx=0 uc_
        uc-runner load-dsl &&
        "${2:?}" || :failp "E$? At ${2@Q}"
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
      local dir="UserConf-Directive-${2}" fail=0 utd=1 &&
      local -n dir_argc=uconf_dir_${2,,}_argc &&
      shift 2 &&
      while [[ $# -gt 0 ]]
      do
        ((uc_idx+=1)) &&
        "$dir" "${2}" "${1}" || {
          uc-status-new --pass && {
            ! uc-status --changed || utd=0
          } || {
            :failp "$UC_STATUS at ${uc_idx}: $dir: sequence '${@:1:${dir_argc:-1}}'"
            fail=1
            uc-status --continue ||  {
              :failp "Aborting"
              break
            }
          }
        }
        shift ${dir_argc-}
      done
      ! ((fail)) || return
      # ((uc_check)) || return 0
      # ((utd)) || return 123
    ;;
    * ) false || :failp "? $FUNCNAME ${*@Q}"
  esac
}
