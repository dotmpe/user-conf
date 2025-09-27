: "${_E_ood:=123}"

uc-assert ()
{
  local ret
  uc-assert-${1:?} "${@:2}"
  ret=$?
  ! ((ret)) || [[ $ret = ${_E_ood:?} ]] ||
  >&2 echo "$FUNCNAME $1 failed for $*"
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
  false
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
  false TODO
}

uc-assert-symlinks ()
{
  local -a _uca_sl_defs=( "$@" )
  uc-symlink --seq _uca_sl_defs
}

uc-assert-copy-or-symlink ()
{
  local boot cleanup
  case "${1}" in
    --boot ) boot=1; shift ;;
    --clean ) cleanup=1; shift ;;
  esac
  local target=${1:?} src=${2:?}
  [[ -f $target ]] || {
    ((boot)) && [[ ! -e $target ]]
  } && {
    uc-copy "$@"
    uc-status-new --pass || :failp "Failed copy <$1>" || return
    ((boot)) && return
    ! ((cleanup)) && return
    >&2 rm -v "${1}"
  }
  uc-symlink "$@"
  uc-status-new --pass || :failp "Failed symlink"
}
