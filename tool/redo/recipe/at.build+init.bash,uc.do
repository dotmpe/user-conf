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

stderr mkdir -vp "${METADIR?}"/build/data

ucbuild_core_sldef=(
  ".bash-env.sh" "${U_C:?}/tool/uc/part/-ucbuild-bash-env.sh"
  ".env-build.sh" "${U_C:?}/tool/uc/part/-ucbuild-env-build.sh"
  ".env-boot.sh" "${U_C:?}/tool/uc/part/-ucbuild-env-boot.sh"
  ".env-static.sh" "${U_C:?}/tool/uc/part/-ucbuild-env-static.sh"
  ".env-local.sh" "${U_C:?}/tool/uc/part/-ucbuild-env-local.sh"
  ".env-pack.sh" "${U_C:?}/tool/uc/part/-ucbuild-env-pack.sh"

  "@build.@/date/default.do" "${U_C:?}/tool/redo/recipe/-uc-build.date-fmt.bash.do"
  "@build.@/make/default.do" "${U_C:?}/tool/redo/recipe/-uc-build.make-basedir.bash.do"

  "default.class.target.do" "tool/redo/recipe/&default.class.target.bash.do"

  "default${BUILD_TARGET_TYPE:-.spec}.do" "${U_C:?}/tool/redo/recipe/-uc-build.build-targets.spec.do"

  "tool/redo/recipe/&default.class.target.bash.do" "${U_C:?}/tool/redo/recipe/default.class.target.bash.do"
  "tool/redo/recipe/&uc-build.build-targets.target.do" "${U_C:?}/tool/redo/recipe/-uc-build.build-targets.target.do"
)

for ((i=0; i<${#ucbuild_core_sldef[*]}; i+=2))
do
  { [[ -e "${EWD:?}/${ucbuild_core_sldef[i]}" ]] || {
      # Remove if broken symlink
      [[ ! -h "${EWD:?}/${ucbuild_core_sldef[i]}" ]] || {
        stderr rm -v "${EWD:?}/${ucbuild_core_sldef[i]}" || {
          $LOG alert ":" "Failed removing symlink" "${ucbuild_core_sldef[i]}"
          exit 3
        }
      }
    }
  } && {
    [[ -d "$(dirname "${EWD:?}/${ucbuild_core_sldef[i]}")" ]] ||
      stderr mkdir -vp "$(dirname "${EWD:?}/${ucbuild_core_sldef[i]}")"
  } && {
    [[ -h "${EWD:?}/${ucbuild_core_sldef[i]}" ]] ||
      stderr ln -vs "${ucbuild_core_sldef[i+1]}" "${EWD:?}/${ucbuild_core_sldef[i]}"
  }
done

[[ ! -s ${BUILD_TARGETS:?} ]] || {
  if_ok "$(grep -oP "([^ ]+)(?=\.[a-z]+: )" "${BUILD_TARGETS:?}")" &&
  for tag in $_
  do
    [[ -e "${EWD:?}/${tag:?}.do" ]] || {
      [[ -h "${EWD:?}/${tag:?}.do" ]] && stderr rm -v "${EWD:?}/${tag:?}.do"
    }
    [[ -h "${EWD:?}/${tag:?}.do" ]] ||
      stderr ln -vs "tool/redo/recipe/&uc-build.build-targets.target.do" \
      "${EWD:?}/$tag.do"
  done && unset tag
}
#
