#!/usr/bin/env bash

## ucbuild:env-static Helper to inject another local script with static defs

# This is intended to be used with ENV_{BOOT,INIT}, to provide functions with
# some standard routines to the environment some of which may be exported as
# well, and used to get more complex envs and customize and export specific
# contexts. See ucbuild-env*

# Boilerplate (copy, see env-local)

case " $ENV_BASE " in ( *" static "* )
  $LOG alert :env-static "Loop detected" "pending=${ENV_PEND-(unset)}" ${_E_ifenv:-121}
;; esac

: "${EWD:=${REDO_BASE:-${CWD:-${PWD?}}}}"

! [[ ${ENV_PEND+set} ]] || {
  [[ ${ENV_PEND%% *} = static ]] || exit ${_E_envif:-121}
  [[ ${#ENV_PEND} = 6 ]] && unset ENV_PEND || ENV_PEND=${ENV_PEND:7}
}

ENV_BASE=${ENV_BASE-}${ENV_BASE+ }static

# Continue env chain or finally include main env, for which there is no tag
[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{_,}$_.sh
do
  [[ -s $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" && unset __ ||
  $LOG alert "" "At env-static" "E$?:pending=${ENV_PEND-(unset)}" ${_E_noenv:-123}

[[ ! ${ENV_PEND+set} ]] ||
  $LOG alert ":env-static" "Expected complete env" "pending: $ENV_PEND" ${_E_noenv:-123}

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info :env-static "Loading additional static source..."

# Boilerplate end:

[[ ${ENV_STATIC+set} ]] || {
  : "${ENV_STATIC_INC:=static}"
  for lib in ${EWD:?}/{,.}{_,}${_}.sh
  do
    test -e "$lib" || continue
    : "${lib:$(( 1 + ${#EWD} ))}"
    #: "${_%.sh}"
    ENV_STATIC=${_:?}
  done && unset lib
}

[[ ! ${ENV_STATIC+set} ]] && {
  $LOG warn :ucbuild:env-static "Static env group is included but no static include was specified"
} || {

  . "${EWD:?}/${ENV_STATIC:?}" || $LOG error :ucbuild:env-static "" E$? $?
}
#
