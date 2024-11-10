#!/usr/bin/env bash

set -eETuo pipefail

# XXX: redo-ifdone @env.BUILD_TARGETS
# XXX: write util: redo-ifdone @build-config/env ||
[[ ${BUILD_TARGETS:+set} && -s "${BUILD_TARGETS-}" ]] ||
{
#  redo-ifchange @build-config/properties &&
#  . "${METADIR:?}/cache/properties.sh" &&
  : "${BUILD_TARGETS:=${METADIR:?}/stat/index/build-targets.local.list}" &&
  [[ -s "${BUILD_TARGETS:?}" ]] ||
    $LOG error "" "Failed getting Build-Target list " "$BUILD_TARGETS" 1
}

# depend on entire table, and then select exact build-target line and use spec
# arguments to stamp this current target.
redo-ifchange "${BUILD_TARGETS:?}" &&
target_name="${REDO_TARGET%${BUILD_TARGET_TYPE:-.spec}}" &&
target_item="$(grep "^.* ${target_name:?}\.[^:]*: " "${BUILD_TARGETS:?}")" &&
: "${target_item%: *}" &&
: "${_#* ${target_name}.}" &&
target_basetype=${_} &&
: "${target_item#* ${target_name:?}.${target_basetype:?}: }"
