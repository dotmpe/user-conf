shdev() {
  env -- HOME SRC_LOCAL SCM_GIT_LOCAL ANNEX_LOCAL
  dir -- \
    "/home/${USER:-$(whoami)}" \
    "$(realpath /src/${local_srv})" \
    "$(realpath ${scm_git_pref:-/srv/scm-git-}${local_srv})" \
    "$(realpath /srv/annex-${local_srv})"
  env -- C_INC U_C U_S UCONF US_BIN HTDOC
  git dotmpe/composure test "" \
    "${SRC_LOCAL}/composure-mpe+dev" "~/project/composure-mpe"
  git "dotmpe/user-conf" "r0.2" "" \
    "${SRC_LOCAL}/user-conf+dev" "~/project/user-conf"
  git "dotmpe/user-scripts" "r0.0" "" \
    "${SRC_LOCAL}/user-scripts+dev" "~/project/user-scripts"
  git "dotmpe/conf-mpe" "master" "" \
    "${SRC_LOCAL}/conf-mpe+dev" "~/.local/share/dotfiles" "~/.conf" "~/project/conf-mpe"
  git "dotmpe/script-mpe" "features/docker-ci" "" \
    "${SRC_LOCAL}/script-mpe+dev" "~/bin" "~/project/script-mpe"
  git "dotmpe/htdocs-mpe" "master" "" \
    "${ANNEX_LOCAL}/htdocs-mpe" "~/htdocs"
  env DOTFILES:=\${HOME}/.conf
  assert-dir "${HOME:?}/.local/"{share,tool/{sh,redo}/part,var}
  symlink -- \
    "${HOME:?}/.l" ".local" -- \
    "${HOME:?}/.l/s" "share" -- \
    "${HOME:?}/.l/s/c" "composure" -- \
    "${HOME:?}/.l/c" "s/c" -- \
    "${HOME:?}/.l/s/composure" "\${DOTFILES:?}/script/composure"
  path -- \
    "$C_INC/tool/bash/exec" \
    "$U_C/bin" \
    "$U_S/bin" \
    "$UCONF/path/Generic" \
    "$UCONF/path/Linux" \
    "$UCONF/script/Generic" \
    "$UCONF/script/Linux" \
    "$UCONF/tool/sh/exec" \
    "$UCONF/tool/py/exec"
}
