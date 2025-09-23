uconf_dir_symlink_argc=2
UserConf-Directive-symlink ()
{
  : id uconf-directives-symlink
  local name=${1} dest=${2} mode=${3-}
  # TODO: mode or other params
  [[ -e "$name" ]] || {
    [[ ! -h "$name" ]] || {
      rm -v "$name" || :failp "Unable to unsymlink ${name@Q}" ||
        return ${_E_continue:=195}
    }
  }
  [[ -h "$name" ]] || {
    ln -vs "$dest" "$name" ||
      :failp "Unable to symlink ${dest@Q} to ${name@Q}" ||
        return ${_E_retry:=198}
  }
}
UserConf-Directive-symlink-map ()
{
  : id uconf-directives-symlink-map
  : about "~ <Array> ... # Define symlinks for each key targetting value"
  : input "${1:?Associative array name}"
  local -n uc_symlink_map=${1}
  local n fail
  local -n ref=${1}[\$n]
  for n in "${!uc_symlink_map[@]}"
  do
    UserConf-Directive-symlink "$n" "${ref}" || {
      test ${_E_continue:?} -eq $? -o ${_E_retry:} -eq $? && fail=1 ||
        return $_
    }
  done
  ! ((${fail:-0}))
}
