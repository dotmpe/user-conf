uc-assert ()
{
  local ret
  uc-assert-${1:?} "${@:2}"
  ret=$?
  ! ((ret)) || [[ $ret = 123 ]]
}

uc-assert-repo-dir-env ()
{
  local -n envs=${1:?}
  local _a
  for _a in "${!envs[@]}"
  do
    local -n env_var=${envs[_a]}
    [[ ${env_var:+set} ]] || {
      ((_a+=1))
      local -n reporef=${2:?}${_a}
      export "${!env_var}=${reporef[3]}" &&
      echo "export ${_}" >> ~/.bashrc &&
      true || return
    }
  done
}

uc-assert-path-env ()
{
  local -n paths=${1:?}
  local path change=false
  for path in "${paths[@]}"
  do
    _OS_Path_Add "${path:?}" || continue
    echo "PATH=\$PATH:$path" >> ~/.bashrc || return
    change=true
  done
  ! "${change:?}" || {
    echo "export PATH" >> ~/.bashrc &&
    export PATH
  }
}

uc-assert-git-checkout ()
{
  :
}

uc-assert-git-checkout-all ()
{
  local -n _uca_gitco
  local i=1
  while >dev/null declare -p $1$i
  do
    _uca_gitco=$1$i
    uc-assert-git-checkout "${_uca_gitco[@]}"

    i=$(( i+1 ))
  done
}

uc-assert-git-mirror ()
{
  :
}

uc-assert-symlinks ()
{
  local -a _uca_sl_defs=( "$@" )
  uc-assert-symlink-all _uca_defs
}

uc-assert-symlink-all ()
{
  local -n _uca_sla_defs=${1:?}
  local utd=true

  for ((i=0; i<${#_uca_sla_defs[*]}; i+=2))
  do
    # Remove on symlink target mismatch or if broken
    [[ -e "${_uca_sla_defs[i]}" ]] && {
      [[ -h "${_uca_sla_defs[i]}" ]] || continue
      target=$(readlink "${_uca_sla_defs[i]}") &&
      [[ $target = "${_uca_sla_defs[i+1]}" ]] && continue
    } || {
      [[ ! -h "${_uca_sla_defs[i]}" ]] ||
      [[ -e "${_uca_sla_defs[i]}" ]] ||
      >&2 rm -v "${_uca_sla_defs[i]}" || {
        >&2 echo ALERT: "Failed removing path or symlink" "${_uca_sla_defs[i]}"
        #_ALERT "Failed removing path or symlink" "${_uca_sla_defs[i]}"
        return 121
      }
    }

    [[ -d "$(dirname "${_uca_sla_defs[i]}")" ]] ||
      >&2 mkdir -vp "$(dirname "${_uca_sla_defs[i]}")" || return
    [[ -h "${_uca_sla_defs[i]}" ]] || {
      >&2 ln -vs "${_uca_sla_defs[i+1]}" "${_uca_sla_defs[i]}" || return
      utd=false
    }
  done
  "${utd:?}" || return 123
}

uc-assert-symlink-or-copy ()
{
  local target=${1:?} dest=${2:?}
  [[ -h $target ]] || {
    ! "${DEV:-false}" && {
      ! "${DEBUG:-false}" || {
        >&2 diff -bqr "$target" "$dest" || return 122
        # $LOG alert : "Local copy is OOD" "E122:doenv/req" 122 || exit $?
      }
    } || {
      >&2 diff -bqr "$target" "$dest" || {
        >&2 cp -v "$dest" "$target" && {
          return 123
          # $LOG warn : "Local file was OOD" "E123:noenv/pend" 123 || exit $?
        } ||
          return 121
          #$LOG alert : "Local file update failed" "E121:ifenv/bug" 121 || exit $?
      }
    }
  }
}
