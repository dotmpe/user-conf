#!/usr/bin/env bash

# uc-build:target.do: Symlink shortcut for targets defined by list file

# XXX:
# This doesnt require any other script but the name of the list file. If none is
# provided (by the local or project env), then it could rely on some other
# buildable target but this does add a direct dependency that will trigger
# current target to rebuild. Should really just depend on one target that
# is symbolic for the env BUILD_TARGETS value only. But the easiest now is just
# to inject (that via env). To check for integrity, should only use something
# like this here:
#redo-ifdone @env.BUILD_TARGETS

set -eETuo pipefail

#us-env -r user-script &&

# XXX: write util: redo-ifdone @build-config/env ||
[[ ${BUILD_TARGETS:+set} && -s "${BUILD_TARGETS-}" ]] ||
{
#  redo-ifchange @build-config/properties &&
#  . "${METADIR:?}/cache/properties.sh" &&
  : "${BUILD_TARGETS:=${METADIR:?}/stat/index/build-targets.local.list}" &&
  [[ -s "${BUILD_TARGETS:?}" ]] ||
    $LOG error "" "Failed getting Build-Target list " "$BUILD_TARGETS" 1
}
target_item="$(grep "^.* ${REDO_TARGET:?}\.[^:]*: " "${BUILD_TARGETS:?}")" &&

case "$target_item" in
( *" ${REDO_TARGET}.alias: "* )
    targets=${target_item#*" ${REDO_TARGET}.alias: "}
    $LOG info ":$REDO_TARGET" "Building alias target..." "$targets"
    redo-ifchange $targets
  ;;

# XXX: recipe and part are practically identical, but not sure which to keep atm

( *" ${REDO_TARGET}.do: "* )
    recipe=${target_item#*" ${REDO_TARGET}.do: "}.do &&
    $LOG info ":$REDO_TARGET" "Building target with recipe script..." "$recipe" &&
    export PATH=${REDO_BASE:?}/tool/redo/recipe:${PATH:?} &&
    recipe_path=$(command -v -- "$recipe") &&
    redo-ifchange "$recipe_path" &&
    . "${_}"
  ;;

( *" ${REDO_TARGET}.fun: "* )
    : "${target_item#*" ${REDO_TARGET}.fun: "}" &&
    "${_}" "$@"
  ;;

( *" ${REDO_TARGET}.part: "* )
    part=${target_item#*" ${REDO_TARGET}.part: "}.sh &&
    $LOG info ":$REDO_TARGET" "Building target with part script..." "$part" &&
    export PATH=${REDO_BASE:?}/tool/redo/part:${PATH:?} &&
    part_path=$(command -v -- "$part") &&
    redo-ifchange "$part_path" &&
    . "${_}"
  ;;

( * ) echo "? ${REDO_TARGET}: No such uc-build.target (in ${BUILD_TARGETS:?})" >&2
    false
  ;;
esac
# uc-build.target
