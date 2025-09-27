uconf_dir_copy_argc=2
uconf_dir_copy_argn=1
: "${uc_copy_force:=0}"
UserConf-Directive-copy ()
{
  : about "Keep copy of name at target"
  : input ${1:?Destination} UserConf-Target-pathref
  : input ${2:?Name reference} UserConf-Source-path
  local dest=${1} name=${2} mode=${3-}
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
UserConf-Directive-copy-seq ()
{
  : id uconf-directives-copy-sequence
  : about "~ <Array> ..."
  : description "Each pair is (source, dest})"
  : input "${1:?Pairs array name}"
  local -n _uconf_d_cp_seq_pairs=${1:?}
  [[ "${_uconf_d_cp_seq_pairs[@]:+set}" ]] || return ${_E_MA:?}
  local offset=0 fail utd=1
  while [[ $offset < ${#_uconf_d_cp_seq_pairs[@]} ]]
  do
    UserConf-Directive-copy "${_uconf_d_cp_seq_pairs[@]:offset:2}" || {
      uc-status-new --pass && {
        ! uc-status --changed || utd=0
      } || fail=1
    }
    shift 2 && ((offset+=2))
  done
  ! ((${fail:-0})) || return
  ((utd)) || return ${_E_ood:?}
}
UserConf-Directive-copy-map ()
{
  : id uconf-directives-copy-map
  : about "~ <Array> ... # Define copys for each key targetting value"
  : description "Each pair is dest->source, ie. reverse from normal argument sequence order"
  : input "${1:?Associative array name}"
  local -n uc_copy_map=${1}
  [[ "${uc_copy_map[@]:+set}" ]] || return ${_E_MA:?}
  local dest fail utd=1
  local -n src=${1}[\$n]
  for dest in "${!uc_copy_map[@]}"
  do
    UserConf-Directive-copy "${src}" "${dest}" || {
      uc-status-new --pass && {
        ! uc-status --changed || utd=0
      } || fail=1
    }
  done
  ! ((${fail:-0})) || return
  ((utd)) || return ${_E_ood:?}
}
