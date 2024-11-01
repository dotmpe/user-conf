#!/usr/bin/env bash

set -eETuo pipefail

[[ ${REDO_RUNID-} && ${REDO_TARGET} = @build+init ]] || {
#[[ ${REDO_RUNID-} && ${BASH_SOURCE[0]} = @build+init+local.do ]] || {
  echo  "Illegal env" && exit 124
}

#us-env -r uc-type &&

#ucbuild_getnode target @build+init &&
#
#$target.run "$@"

#us-env -r user-script &&

#lib_require sys os build-uc &&
#
#ucbuild_do4124 uc:at.build+init.bash.do "$@"

#us-env -r uc-build &&
#redo-ifdone \$config+build+init &&

ucbuild_core_sldef=(
  ".bash-env.sh" "${U_C:?}/tool/uc/part/-ucbuild-bash-env.sh"
  ".env-build.sh" "${U_C:?}/tool/uc/part/-ucbuild-env-build.sh"
  ".env-boot.sh" "${U_C:?}/tool/uc/part/-ucbuild-env-boot.sh"
  ".env-static.sh" "${U_C:?}/tool/uc/part/-ucbuild-env-static.sh"
  ".env-local.sh" "${U_C:?}/tool/uc/part/-ucbuild-env-local.sh"
  ".env-pack.sh" "${U_C:?}/tool/uc/part/-ucbuild-env-pack.sh"

  "tool/redo/recipe/&uc-build.build-targets.target.do" "${U_C:?}/tool/redo/recipe/-uc-build.target.do"
)

for ((i=0; i<${#ucbuild_core_sldef[*]}; i+=2))
do
  [[ -h "${EWD:?}/${ucbuild_core_sldef[i]}" ]] ||
    stderr ln -vs "${ucbuild_core_sldef[i+1]}" "${EWD:?}/${ucbuild_core_sldef[i]}"
done

if_ok "$(grep -oP "([^ ]+)(?=\.[a-z]+: )" "${BUILD_TARGETS:?}")" &&
for tag in $_
do [[ -h "${EWD:?}/${tag:?}.do" ]] ||
    stderr ln -vs "tool/redo/recipe/&uc-build.build-targets.target.do" \
    "${EWD:?}/$tag.do"
done && unset tag

#
