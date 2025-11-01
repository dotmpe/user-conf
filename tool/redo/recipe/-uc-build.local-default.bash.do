#!/usr/bin/env bash

# Derived from user.default.bash.do

set -euETo pipefail

[[ ${REDO_RUNID-} && ${BASH_SOURCE[0]} = default.do ]] || {
  >&2 echo "$0: Illegal env (must be run from Redo)"
  exit ${_E_noenv:-123}
}

: "${UC_BUILD_ENVS_TRY:=./.build-env.sh ./.local-env.sh ./.env.sh}"
uc_build_envs_try=( ${UC_BUILD_ENVS_TRY} )
_Sys_Exec_Apply first_scr . uc_build_envs_try ||
  failerr "E$? while looking for build env" || exit

# XXX: for all those use cases to work, need to change boilerplate to
#us-env -r user-script -- "$@" &&

# XXX: rewrite to us-env -r uc-build &&
#lib_require sys os build-uc &&

#ucbuild_do4124 uc-build.local-default.bash.do "$@"

xredo_target="${REDO_PWD:+$REDO_PWD/}${REDO_TARGET:?}"

[[ ${uc_build_selects:+set} ]] || {
  declare -ga uc_build_selects
  uc_build_selects=(
    "uc-build.redo-select.bash.do"
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
