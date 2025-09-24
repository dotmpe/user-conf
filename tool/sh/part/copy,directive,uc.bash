uconf_dir_copy_argc=2
uconf_dir_copy_argn=1
: "${uc_copy_force:=0}"
UserConf-Directive-copy ()
{
  : about "Keep copy of name at target"
  : input ${1:?Name reference} UserConf-Source-path
  : input ${2:?Destination} UserConf-Target-pathref
  local name=${1} dest=${2} mode=${3-}
  # TODO: mode or other params
  [[ -f "${name}" ]] || {
    :fail "Expected local file ${name@Q}" ${_E_continue:?} || return
  }
  shift
  [[ -s "${dest}" ]] && {
    diff -bqr "${name}" "${dest}" && return 0
    >&2 "copy ${dest} for ${name} is out of sync"
  } ||  {
    [[ -s "${name}" ]] || return 0
  }
  [[ ! -e "${dest}" ]] || {
    ((uc_copy_force)) ||
      :fail "TODO: resolve diff ${name} ${dest} or set uc_copy_force=1" ${_E_retry:?} || return
     mv "${dest}"{,.local}
  }
  cp -v "${name}" "${dest}" || return ${_E_retry:?}
}
