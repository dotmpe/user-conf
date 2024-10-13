#!/usr/bin/env bash

## The main project redo script controls project lifecycle and workflows.

# Remove settings from file so they don't affect all builds.

for BUILD_SEED in \
  ${REDO_STARTDIR:?}/.env.sh \
  ${REDO_STARTDIR:?}/.build-env.sh
do
  test ! -e "${BUILD_SEED:?}" && continue
  source "${BUILD_SEED:?}" >&2 || exit $?
done

# Start standardized redo for build.lib
: "${REDO_DEFAULT_DO:=${UCONF?}/tool/redo/local.do}"
[[ -e $REDO_DEFAULT_DO ]] ||
  : "${REDO_DEFAULT_DO:=${U_C:?}/tool/redo/local.do}"

. "${REDO_DEFAULT_DO:?}"

# Sync: UCONF
# Id: User-Conf:default.do                                     ex:ft=bash:
