ucinit() {
  path $UC_INIT/tool/uc/part

  uc-part --simple --all "uc-assert.directive-handlers.bash" \
    "copy,directive,uc.bash" "commands,uc.bash" ||
    :err echo "E$? at ucinit:$uc_idx" || return

  uc-assert-copy-or-symlink --boot .env-build.sh   $UC_INIT/tool/uc/part/-ucbuild-env-build.sh &&
  uc-assert-copy-or-symlink --boot .env-init.sh    $UC_INIT/tool/uc/part/-ucbuild-env-init.sh &&
  uc-assert-copy-or-symlink --boot .env-local.sh   $UC_INIT/tool/uc/part/-ucbuild-env-local.sh &&
  uc-assert-copy-or-symlink --boot .env-pack.sh    $UC_INIT/tool/uc/part/-ucbuild-env-pack.sh &&
  uc-assert-copy-or-symlink --boot .env-static.sh  $UC_INIT/tool/uc/part/-ucbuild-env-static.sh &&
  uc-assert-copy-or-symlink --boot .env.sh.do      $UC_INIT/tool/uc/part/-ucbuild-env-default,do.sh &&
  uc-assert-copy-or-symlink --boot .init-env.sh    $UC_INIT/tool/sh/part/init-env,uc.sh &&
  uc-assert-copy-or-symlink --boot .local-env.sh   $UC_INIT/tool/sh/part/local-env,uc.sh &&
  uc-assert-copy-or-symlink --boot .bash-env.sh    $UC_INIT/tool/sh/part/bash-env,uc.bash &&
  uc-assert-copy-or-symlink --boot .bash-env2.sh   $UC_INIT/tool/sh/part/bash-env2,uc.bash &&
  uc-assert-copy-or-symlink --boot .common.sh      $UC_INIT/tool/sh/part/common,inc,uc.bash &&
  true ||
    :err echo "E$? at ucinit:$uc_idx" || return

  symlink -- \
    $HOME/.l ".local" \
    $HOME/.local/s share \
    $HOME/.local/s/composure /srv/src-local/local/user-conf+dev/script/composure \
    $HOME/.local/c s/composure \
    $HOME/.local/user $UCONF/user ||
    :err echo "E$? at ucinit:$uc_idx" || return

  for target in "${ucinit_targets[@]}"
  do
    [[ -e $UC_INIT/tool/redo/recipe/at.${target}.bash,uc.do ]] && {
      symlink @${target}.do $UC_INIT/tool/redo/recipe/at.${target}.bash,uc.do
    } || {
      symlink @${target}.do.do $UC_INIT/tool/redo/recipe/at.default+init.bash,uc.do
      pending+=( @${target}.do )
    }
  done ||
    :err echo "E$? at ucinit:$uc_idx" || return

  # @local{env,uc}
  symlink @localenv.do $UC_INIT/tool/redo/part/at.local-env.bash,uc.do &&
  symlink @localuc.do  $UC_INIT/tool/redo/part/at.local-uc.bash,uc.do  &&
  true ||
    :err echo "E$? at ucinit:$uc_idx" || return

  pending+=( .env.sh .env-init.sh )
}
