#!/usr/bin/env bash

set -euo pipefail

[[ ${REDO_RUNID-} && ${REDO_TARGET} = @build+init ]] || {
#[[ ${REDO_RUNID-} && ${BASH_SOURCE[0]} = @build+init+local.do ]] || {
  echo  "Illegal env" && exit 124
}

us-env -r uc-type &&

uctype__getnode target @build+init &&

$target.run "$@"

#us-env -r user-script &&
#
#lib_require sys os build-uc &&
#
#ucbuild_do4124 uc:at.build+init.bash.do "$@"

#
