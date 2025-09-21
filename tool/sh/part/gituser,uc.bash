gituser() {
  local uc=${UC_INIT:-${UCONF}}
  pushd "$uc"
  : ${gituser_config_skeleton:=default}
  : ${gituser_config_tag:=mpe}
  symlink etc/git/skeleton/${gituser_config_skeleton}.config ~/.gitconfig
  symlink etc/git/base/${gituser_config_tag}.config ~/.gitconfig-base
  symlink etc/git/user/${gituser_config_tag}.config ~/.gitconfig-user
  symlink etc/git/global/${gituser_config_tag}.config ~/.gitconfig-global
  symlink etc/git/local/${OS_HOSTNAME}.config ~/.gitconfig-local
  symlink etc/git/gitignore-global ~/.gitignore-global
}
