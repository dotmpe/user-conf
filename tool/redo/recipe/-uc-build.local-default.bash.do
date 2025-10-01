#!/usr/bin/env bash

# Derived from user.default.bash.do

set -euETo pipefail

[[ ${REDO_RUNID-} && ${BASH_SOURCE[0]} = default.do ]] || {
  >&2 echo "$0: Illegal env (must be run from Redo)"
  exit 124
}

# XXX: for all those use cases to work, need to change boilerplate to
#us-env -r user-script -- "$@" &&

# XXX: rewrite to us-env -r uc-build &&
#lib_require sys os build-uc &&

#ucbuild_do4124 uc-build.local-default.bash.do "$@"

xredo_target="${REDO_PWD:+$REDO_PWD/}${REDO_TARGET:?}"

[[ ${uc_build_selects:+set} ]] || {
  declare -ga uc_build_selects
  uc_build_selects+=( \
    "uc-build.host-env-select.bash.do"
    #"uc-build.local-env-select.bash.do"
  )
  : "${U_C:=/src/local/user-conf+${CTX_ENV:-dev}}"
  os_path_add ${U_C:?}/tool/redo/recipe
}

for build_select_sh in "${uc_build_selects[@]}"
do
  xredo_build_select=${build_select_sh%.do}
  . "${build_select_sh:?}" && exit ||
  test ${_E_next:-196} -eq $? || exit
done

>&2 echo "uc-build.local-default: Unknown target $1"
exit 1

# ex:ft=bash:
