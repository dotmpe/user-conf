sshuser() {
  local uc=${UC_INIT:-${UCONF}}
  pushd "$uc"
  : ${sshuser_config:=default}
  copy etc/ssh/${sshuser_config}.config ~/.ssh/config
  part ssh{key,agent}user
  symlink ~/.ssh/known_hosts tokens/ssh/${OS_HOSTNAME}-${USER}.known_hosts
  clean ~/.ssh/known_hosts{.old,}
  : ${sshuser_keyname:=id_rsa}
  symlink ~/.ssh/${sshuser_keyname}.pub tokens/ssh/${OS_HOSTNAME}-${sshuser_keyname}.pub
  line-word ENV_PART sshuser .env
  line sshkeysuser ~/.bashrc
  popd
}
