#!/usr/bin/env bash

## ucbuild:env-static Helper to inject another local script with static defs

# This is intended to be used with ENV_{BOOT,INIT}, to provide functions with
# some standard routines to the environment some of which may be exported as
# well, and used to get more complex envs and customize and export specific
# contexts. See ucbuild-env*

# Boilerplate (copy, see env-local)

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info ":ucbuild[$$]:env-static" "Static env loading..."

case " ${ENV_BASE-} " in ( *" static "* )
  $LOG alert ":ucbuild[$$]:env-pack" "Loop detected" \
    "base=${ENV_BASE-(unset)},pending=${ENV_PEND-(unset)}" ${_E_ifenv:-121} ||
      return
;; esac

[[ ${ENV_PEND+set} ]] ||
  $LOG alert ":ucbuild[$$]:env-static" "Unverified env" "" ${_E_ifenv:-121} ||
    return

[[ ${ENV_PEND%% *} = static ]] || return ${_E_ifenv:-121}
[[ ${#ENV_PEND} = 6 ]] && unset ENV_PEND || ENV_PEND=${ENV_PEND:7}

ENV_BASE=${ENV_BASE-}${ENV_BASE+ }static

# Continue env chain or finally include main env, for which there is no tag
[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{_,}$_.sh
do
  [[ -e $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" ||
  $LOG alert ":ucbuild[$$]:env-static" "Failure resolving base env" \
    "E$?:base=${ENV_BASE-(unset)}:pend=${ENV_PEND-(unset)}" ${_E_noenv:-123} ||
      return

[[ ! ${ENV_PEND+set} ]] || $LOG alert ":ucbuild[$$]:env-static" \
  "Expected complete env" "pending:$ENV_PEND" ${_E_noenv:-123} || return

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info ":ucbuild[$$]:env-static" "Ready to static source..."

# Boilerplate end:

# Track time, so ENV_STATIC mtime can be verified if needed
: "$(</proc/uptime)"
ENV_STATIC_TIME=${_% *}

# Get the ENV_STATIC script file path
[[ ${ENV_STATIC+set} ]] || {
  : "${ENV_STATIC_INC:=static}"
  for __env_static in ${EWD:?}/{,.}{_,}${_}.sh
  do
    test -e "$__env_static" || continue
    : "${__env_static:$(( 1 + ${#EWD} ))}"
    #: "${_%.sh}"
    ENV_STATIC=${_:?}
    break
  done && unset __env_static
}

# Verbose source for ENV_STATIC
[[ ! ${ENV_STATIC+set} ]] && {
  $LOG warn ":ucbuild[$$]:env-static" \
    "Static env group is included but no static include was specified"
} || {
  . "${EWD:?}/${ENV_STATIC:?}" ||
    $LOG error ":ucbuild[$$]:env-static" "While sourcing script" \
      "E$?:$ENV_STATIC_INC" $?
}

#
