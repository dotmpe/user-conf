#!/usr/bin/env bash

## Lookup recipe name on */tools/redo/recipe/

# XXX: static inline config
: "${XREDO_PATH:=${C_INC:?}/tool/redo/recipe:${US_BIN:?}/tool/redo/recipe:${U_C:?}/tool/redo/recipe:${U_S:?}/tool/redo/recipe:${US_INC:?}/tool/redo/recipe:${REDO_BASE:?}/tool/redo/recipe}"

XREDO_NAME=${2:?}
case "$XREDO_NAME" in
  @* )
      XREDO_NAME=${XREDO_NAME:1}.class.target
    ;;
esac

declare -a exec_cmd

export PATH=${XREDO_PATH:?}:${PATH:?}

if_ok "$(command -v "${XREDO_NAME:?}.bash.do")" &&
exec_cmd=(
  source -- "${XREDO_NAME:?}.bash.do"
) || {
  if_ok "$(command -v "${XREDO_NAME:?}.do")" &&
  exec_cmd=(
    source -- "${XREDO_NAME:?}.do"
  ) ||
    $LOG error "" "Missing bash or shell recipe" "E$?:$XREDO_NAME" $?
}

"${exec_cmd[@]:?No command for $XREDO_NAME}"
#
