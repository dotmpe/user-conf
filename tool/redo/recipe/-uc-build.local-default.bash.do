#!/usr/bin/env bash

set -euo pipefail

# XXX: symlinked to <localdir>/default.do

[[ ${REDO_RUNID-} && ${BASH_SOURCE[0]} = default.do ]] ||
  $LOG alert "" "Illegal env" "" 124

us-env -r user-script &&
# XXX: for all those use cases to work, need to change boilerplate to
#us-env -r user-script -- "$@" &&

# XXX: rewrite to us-env -r uc-build &&
lib_require sys os build-uc &&

ucbuild_do4124 uc-build.local-default.bash.do "$@"
