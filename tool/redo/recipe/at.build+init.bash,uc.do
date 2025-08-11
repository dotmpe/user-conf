#!/usr/bin/env bash

# The @build+init is a global, universal target with a specific, bespoke
# implementation. Current version monitors symlinks specified inline with
# ucbuild_core_sldef[<Name>]=<Target>, and checks targets in root BuildTargets
# for names matching existing parts and symlinks those.

# Later work should move functions in to a universal @auto and @conf{,ig} target
# and recipe, rewriting this to be more dynamic metadata driven setup. Current
# work is offering a Redo install path/profile for init-linux and @shdev+init to
# ensure Git base is UTD*.

# * XXX: @build+init tracks updates by putting metadata dump in redo-stamp so
# it can track state change, but it has no external sources declared (or
# embedded redo-always) to trigger updates, so redo-ifchange will only re-run
# the target if the recipe is actually modified; otherwise explicit redo calls
# will run the script.

set -eETuo pipefail

[[ ${REDO_RUNID-} && ${REDO_TARGET} = @build+init ]] || {
#[[ ${REDO_RUNID-} && ${BASH_SOURCE[0]} = @build+init+local.do ]] || {
  echo  "Illegal env" && exit 124
}

# Keep this recipe UTD automatically
[[ -h @build+init.do ]] || {
  ! "${DEV:-false}" && {
    ! "${DEBUG:-false}" || {
      >&2 diff -bqr @build+init.do \
      "${U_C:?}"/tool/redo/recipe/at.build+init.bash,uc.do ||
        $LOG alert : "Local recipe is OOD" "E122:doenv/req" 122 || exit $?
    }

  } || {

    >&2 diff -bqr @build+init.do \
      "${U_C:?}"/tool/redo/recipe/at.build+init.bash,uc.do || {

      >&2 cp -v "${U_C:?}"/tool/redo/recipe/at.build+init.bash,uc.do @build+init.do && {
        $LOG warn : "Local recipe was OOD" "E123:noenv/pend" 123 || exit $?
      } ||
        $LOG alert : "Local recipe update failed" "E121:ifenv/bug" 121 || exit $?
    }
  }
}


## Initialize/update shell dev env (local and host)

[[ -e @shdev+init.do ]] ||
>&2 ln -vs "${U_C:?}"/tool/redo/recipe/at.shdev+init.bash,uc.do @shdev+init.do

redo-ifchange @shdev+init &&

. ./.env-init.sh || exit


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


  "@build:/date:/default.do" "${U_C:?}/tool/redo/recipe/-uc-build.date-fmt.bash.do"

  "@build:/filestat,os:/default.do" "../../tool/redo/recipe/&default.filestat.os.do"

  "@build:/filestat,os:/index.userdir.do" "../../tool/redo/recipe/&default.filestat.os.do"
  "index.filestat.userdir.os.do" "tool/redo/recipe/&default.filestat.os.do"

  "@build:/filestat,os:/default.userdir.do" "../../tool/redo/recipe/&default.filestat.os.do"
  "default.filestat.userdir.os.do" "tool/redo/recipe/&default.filestat.os.do"

  "@build:/make:/default.do" "${U_C:?}/tool/redo/recipe/-uc-build.make-basedir.bash.do"

  "@build:/user:/default.user-screenshots.do" "../../tool/redo/recipe/&default.user-screenshots.do"

  "@build:/dedupe,sha1:/default.do" "../../tool/redo/recipe/&default.dedupe-sha1.do"
  "@build:/dedupe,sha1:./default.do" "../../tool/redo/recipe/&default.dedupe-sha1.do"

  "@build:/bittorrent:/default.do" "../../tool/redo/recipe/&default.transmission-bt.do"

  "default.class.target.do" "tool/redo/recipe/&default.class.target.bash.do"

  "default${BUILD_TARGET_TYPE:-.spec}.do" "${U_C:?}/tool/redo/recipe/-uc-build.build-targets.spec.do"

  "tool/redo/recipe/&default.class.target.bash.do" "${U_C:?}/tool/redo/recipe/default.class.target.bash.do"
  "tool/redo/recipe/&uc-build.build-targets.target.do" "${U_C:?}/tool/redo/recipe/-uc-build.build-targets.target.do"
  "tool/redo/recipe/&default.filestat.os.do" "${UCONF:?}/tool/redo/recipe/-os-filestat.bash.do"
  "tool/redo/recipe/&default.transmission-bt.do" "${UCONF:?}/tool/redo/recipe/-bt-transmission.bash.do"
  "tool/redo/recipe/&default.user-screenshots.do" "${UCONF:?}/tool/redo/recipe/-user-screenshots.bash.do"
  "tool/redo/recipe/&default.dedupe-sha1.do" "${UCONF:?}/tool/redo/recipe/-uc-dedupe,sha1.do"
)

for ((i=0; i<${#ucbuild_core_sldef[*]}; i+=2))
do
  [[ -e "${EWD:?}/${ucbuild_core_sldef[i]}" ]] || {
    # Remove if broken symlink
    [[ ! -h "${EWD:?}/${ucbuild_core_sldef[i]}" ]] || {
      >&2 rm -v "${EWD:?}/${ucbuild_core_sldef[i]}" || {
        _ALERT "Failed removing symlink" "${ucbuild_core_sldef[i]}"
        exit 3
      }
    }
  }
  [[ -d "$(dirname "${EWD:?}/${ucbuild_core_sldef[i]}")" ]] ||
    >&2 mkdir -vp "$(dirname "${EWD:?}/${ucbuild_core_sldef[i]}")"
  [[ -h "${EWD:?}/${ucbuild_core_sldef[i]}" ]] ||
    >&2 ln -vs "${ucbuild_core_sldef[i+1]}" "${EWD:?}/${ucbuild_core_sldef[i]}"
done

# Process local BuildTargets file
[[ ! -s ${BUILD_TARGETS:?} ]] &&
_IFVBS _WARN "Empty or missing build targets file <$BUILD_TARGETS>" || {

  if_ok "$(grep -oP "([^ ]+)(?=\.[a-z]+: )" "${BUILD_TARGETS:?}")" &&
  for tag in $_
  do
    # XXX: Easiest is to just re-link so... should probably rewrite
    [[ -e "${EWD:?}/${tag:?}.do" ]] || {
      [[ -h "${EWD:?}/${tag:?}.do" ]] && >&2 rm -v "${EWD:?}/${tag:?}.do"
    }
    [[ -h "${EWD:?}/${tag:?}.do" ]] ||
      >&2 ln -vs "tool/redo/recipe/&uc-build.build-targets.target.do" \
      "${EWD:?}/$tag.do"
  done && unset tag
}

# ex:ft=bash:
