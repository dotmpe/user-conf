#!/usr/bin/env bash

# Boilerplate (derived from env-local)

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  _ _INFO "Build env loading..."

case " ${ENV_BASE-} " in ( *" build "* )
  _ALERT "Loop detected" "" ${_E_ifenv:-121} || return
;; esac

[[ ${ENV_PEND+set} ]] ||
  _ALERT "Unverified env" "foo=bar" ${_E_ifenv:-121} ||
    return

[[ ${ENV_PEND%% *} = build ]] || return ${_E_ifenv:-121}
[[ ${#ENV_PEND} = 5 ]] && unset ENV_PEND || ENV_PEND=${ENV_PEND:6}

ENV_BASE=${ENV_BASE-}${ENV_BASE+ }build

# Continue env chain or finally include main env, for which there is no tag
[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{_,}$_.sh
do
  [[ -e $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" ||
  _ALERT "Failure resolving base env" "" ${_E_noenv:-123} || ${uc_stat}

[[ ! ${ENV_PEND+set} ]] ||
  _ALERT "Expected complete env" "" ${_E_noenv:-123} || return

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  _ _INFO "Build env start"

# Boilerplate end:

# The env-build also inserts a default Env-Init that env-boot would pick up
: "${PACK_ID:=${APP_ID:?env-build: package ID default; expected APP env}}"
: "${ENV_BASE//[^A-Za-z0-9_]/_}"
: "${ENV_INIT:=${PACK_ID//[^A-Za-z0-9_]/_}_env_${_:?}_init}"

: "${BUILD_TOOL:=redo}"
: "${BUILD_ID:=${REDO_RUNID:?}}"
: "${BUILD_BASE:=${REDO_BASE:?}}"
#: "${BUILD_PWD:="${REDO_PWD:-${CWD:${#BUILD_BASE}}}"}"
#test -z "$BUILD_PWD" || BUILD_PWD=${BUILD_PWD:1}
#BUILD_SCRIPT=${BUILD_PWD}${BUILD_PWD:+/}default.do
#test -z "$BUILD_PWD" && BUILD_PATH=$CWD || BUILD_PATH=$CWD:$BUILD_BASE
#BUILD_PATH=$BUILD_PATH:${UCONF:?}:${U_C:?}:${U_S:?}
: "${METADIR:?env-build: expected METADIR env}"
: "${BUILD_TARGETS:=${_}/stat/index/build-targets.local.list}"

: "${A:=@build:}"

# TODO: load this from local build dir and prepare under @localuc target
uc_build_selects=(
  "uc-build.host-env-select.bash.do"
  "uc-build.local-select.bash.do"
  "uc-build.composure-select.bash.do"
  "uc-build.redo-select.bash.do"
)

#
