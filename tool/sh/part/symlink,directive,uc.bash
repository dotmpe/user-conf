uconf_dir_symlink_argc=2
uconf_dir_symlink_argm=3
UserConf-Directive-symlink ()
{
  : about "Symlink name to target"
  : input ${1:?Name reference} UserConf-Source-path
  : input ${2:?Destination} UserConf-Target-pathref
  : id uconf-directives-symlink
  local name=${1} dest=${2} mode=${3-}
  # TODO: mode or other params
  [[ -f "$name" ]] || {
    [[ ! -h "$name" ]] ||
      rm -v "$name" ||
        :fail "E$? Unable to unsymlink ${name@Q}" ${_E_continue:?} || return
  }
  [[ -h "$name" ]] ||
  [[ ! -e "$name" ]] && {
    ln -vs "$dest" "$name" && return ${_E_next:?} ||
      :fail "E$? Failed symlinking ${name@Q} to ${dest@Q}" ${_E_retry:?} ||
        return
  } ||
    :fail "Unable to symlink ${name@Q} over existing ${dest@Q}" ${_E_continue:?}
}
UserConf-Directive-symlink-seq ()
{
  : id uconf-directives-symlink-sequence
  : about "~ <Array> ..."
  : description "Each pair is (source, dest})"
  : input "${1:?Pairs array name}"
  local -n _uconf_d_sl_seq_pairs=${1:?}
  [[ "${_uconf_d_sl_seq_pairs[@]:+set}" ]] || return ${_E_MA:?}
  local offset=0 fail utd=1
  while [[ $offset < ${#_uconf_d_sl_seq_pairs[@]} ]]
  do
    UserConf-Directive-symlink "${_uconf_d_sl_seq_pairs[@]:offset:2}" || {
      test ${_E_continue:?} -eq $? -o ${_E_retry:?} -eq $? && fail=1 ||
      test ${_E_next:?} -eq $_ && utd=0 || return $_
    }
    shift 2 && ((offset+=2))
  done
  ! ((${fail:-0})) || return
  ((utd)) || return 123
}
UserConf-Directive-symlink-map ()
{
  : id uconf-directives-symlink-map
  : about "~ <Array> ... # Define symlinks for each key targetting value"
  : description "Each pair is dest->source, ie. reverse from normal argument sequence order"
  : input "${1:?Associative array name}"
  local -n uc_symlink_map=${1}
  [[ "${uc_symlink_map[@]:+set}" ]] || return ${_E_MA:?}
  local n fail utd=1
  local -n ref=${1}[\$n]
  for n in "${!uc_symlink_map[@]}"
  do
    UserConf-Directive-symlink "${ref}" "$n" || {
      test ${_E_continue:?} -eq $? -o ${_E_retry:?} -eq $? && fail=1 ||
      test ${_E_next:?} -eq $_ && utd=0 || return $_
    }
  done
  ! ((${fail:-0})) || return
  ((utd)) || return 123
}
