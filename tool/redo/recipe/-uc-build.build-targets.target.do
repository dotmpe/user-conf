#!/usr/bin/env bash

# uc-build:target.do: Symlink shortcut for targets defined by list file

set -eETuo pipefail

# local helper to defer to uc-build handler function
_ucbuild_build_targets_target_ ()
{
  us-env -r user-script &&
  lib_require build-uc &&
  target_spec=${target_item#*" ${REDO_TARGET}.${1:?}: "} &&
  uc_build --target-type:"${1:?}" "$target_spec" "${@:2}"
}

: "${BUILD_TOOL:=redo}"
declare -x BUILD_TOOL

# Rebuild target if spec changes using another recipe (see default.spec.do)
"${BUILD_TOOL?}"-ifchange "${REDO_TARGET:?}${BUILD_TARGET_TYPE:-.spec}" &&

# Get spec and execute recipe. As the current recipe file is an implicit
# prerequisite, changes to it will trigger all target instances! This is fine
# for types that are mature and doing exactly as intended, but inconventient
# during development. XXX: working on build-rule conversion, add some
# dynamic env based mapping after first trying builtin case/esac

target_item="$(grep "^.* ${REDO_TARGET:?}\.[^:]*: " "${BUILD_TARGETS:?}")" &&

case "$target_item" in


# Basic target types

( *" ${REDO_TARGET}.alias: "* )
    targets=${target_item#*" ${REDO_TARGET}.alias: "}
    $LOG info ":$REDO_TARGET" "Building alias target..." "$targets"
    "${BUILD_TOOL?}"-ifchange $targets
  ;;

( *" ${REDO_TARGET}.do: "* )
    _ucbuild_build_targets_target_ do "$@"
  ;;

( *" ${REDO_TARGET}.fun: "* )
    : "${target_item#*" ${REDO_TARGET}.fun: "}" &&
    "${_}" "$@"
  ;;


# Other special target types

( *" ${REDO_TARGET}.cache: "* )
    _ucbuild_build_targets_target_ cache
  ;;

( *" ${REDO_TARGET}.part: "* )
    _ucbuild_build_targets_target_ part
  ;;

( *" ${REDO_TARGET}.rule: "* )
    _ucbuild_build_targets_target_ rule
  ;;


( * ) echo "? ${REDO_TARGET}: No such uc-build.target (in ${BUILD_TARGETS:?})" >&2
    false
esac
# uc-build.target
