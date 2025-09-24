ucinit() {
  path $UC_INIT/tool/uc/part
  copy -- \
    $UC_INIT/tool/uc/part/-ucbuild-env-build.sh .env-build.sh \
    $UC_INIT/tool/uc/part/-ucbuild-env-init.sh .env-init.sh \
    $UC_INIT/tool/uc/part/-ucbuild-env-local.sh .env-local.sh \
    $UC_INIT/tool/uc/part/-ucbuild-env-pack.sh .env-pack.sh \
    $UC_INIT/tool/uc/part/-ucbuild-env-static.sh .env-static.sh \
    $UC_INIT/tool/uc/part/-ucbuild-env-default,do.sh .env.sh.do \
    $UC_INIT/tool/sh/part/init-env,uc.sh .init-env.sh \
    $UC_INIT/tool/sh/part/local-env,uc.sh .local-env.sh \
    $UC_INIT/tool/sh/part/bash-env,uc.bash .bash-env.sh \
    $UC_INIT/tool/sh/part/common,inc,uc.bash .common.sh
  for target in "${ucinit_targets[@]}"
  do
    [[ -e $UC_INIT/tool/redo/recipe/at.${target}.bash,uc.do ]] && {
      symlink $UC_INIT/tool/redo/recipe/at.${target}.bash,uc.do @${target}.do
    } || {
      symlink $UC_INIT/tool/redo/recipe/at.default+init.bash,uc.do @${target}.do.do
    }
  done
  # @local{env,uc}
  symlink $UC_INIT/tool/redo/part/at.local-env.bash,uc.do @localenv.do
  symlink $UC_INIT/tool/redo/part/at.local-uc.bash,uc.do @localuc.do
}
