uconf_dir_symlink_argnum=2
uconf_dir_symlink_argmax=3
User-Conf.Directive.symlink ()
{
: about "Symlink name to target"
: param '~ <Link-path> <Source-path> [<Mode>]'
: input ${1:?Destination} UserConf-Target-pathref
: input ${2:?Name reference} UserConf-Source-path
: id uconf-directives-symlink
  local trgtref=${1} rdest name=${2} mode=${3-}
  # TODO: mode or other params
  [[ "${trgtref:0:1}" = / ]] &&
    rdest=$trgtref ||
    #rdest=$(cd "${name%/*}" && realpath "${trgtref}")
    rdest="${name%/*}/${trgtref}"
  test -e "${name}" || fail "No such source ${_@Q}" 127 || return
  [[ -f "$rdest" ]] || {
    [[ ! -h "$rdest" ]] ||
      [[ $(readlink $name) = "$trgtref" ]] ||
        rm -v "$rdest" ||
          fail "E$? Unable to unsymlink ${rdest@Q}" ${_E_continue:?} || return
  }
  [[ -h "$name" ]] && return
  [[ ! -e "$name" ]] && {
    ln -vs "$name" "$trgtref" && return ${_E_next:?} ||
      fail "E$? Failed symlinking ${rdest@Q} at ${name@Q}" ${_E_retry:?} ||
        return
  } ||
    fail "Unable to symlink ${rdest@Q} at existing ${name@Q}" ${_E_continue:?}
}

User-Conf.Directive.symlink-seq ()
{
: id uconf-directives-symlink-sequence
: about "~ <Array> ..."
: description "Each pair is (source, dest}), ie. reverse from normal arg sequence"
: input "${1:?Pairs array name}"
  local -n _uconf_d_sl_seq_pairs=${1:?}
  [[ "${_uconf_d_sl_seq_pairs[@]:+set}" ]] || return ${_E_MA:?}
  local offset=0 fail utd=1
  while [[ $offset < ${#_uconf_d_sl_seq_pairs[@]} ]]
  do
    User-Conf.Directive.symlink "${_uconf_d_sl_seq_pairs[@]:offset:2}" || {
      uc-status-new --pass && {
        ! uc-status --changed || utd=0
      } || fail=1
    }
    shift 2 && ((offset+=2))
  done
  ! ((${fail:-0})) || return
  ((utd)) || return ${_E_ood:?}
}
User-Conf.Directive.symlink-map ()
{
: id uconf-directives-symlink-map
: about "~ <Array> ... # Define symlinks for each key targetting value"
: description "Each pair is dest->source, ie. normal arg seq order"
: input "${1:?Associative array name}"
  local -n uc_symlink_map=${1}
  [[ "${uc_symlink_map[@]:+set}" ]] || return ${_E_MA:?}
  local n fail utd=1
  local -n ref=${1}[\$n]
  for n in "${!uc_symlink_map[@]}"
  do
    User-Conf.Directive.symlink "$n" "${ref}" || {
      uc-status-new --pass && {
        ! uc-status --changed || utd=0
      } || fail=1
    }
  done
  ! ((${fail:-0})) || return
  ((utd)) || return ${_E_ood:?}
}
