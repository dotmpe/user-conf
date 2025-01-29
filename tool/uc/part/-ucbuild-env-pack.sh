#!/usr/bin/env bash

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info ":ucbuild[$$]:env-pack" "Pack env loading..."

case " ${ENV_BASE-} " in ( *" pack "* )
  $LOG alert ":ucbuild[$$]:env-pack" "Loop detected" \
    "base=${ENV_BASE-(unset)},pending=${ENV_PEND-(unset)}" ${_E_ifenv:-121} ||
      return
;; esac

[[ ${ENV_PEND+set} ]] ||
  $LOG alert ":ucbuild[$$]:env-pack" "Unverified env" "" ${_E_ifenv:-121} ||
    return

[[ ${ENV_PEND%% *} = pack ]] || return ${_E_ifenv:-121}
[[ ${#ENV_PEND} = 4 ]] && unset ENV_PEND || ENV_PEND=${ENV_PEND:5}

ENV_BASE=${ENV_BASE-}${ENV_BASE+ }pack

# Continue env chain or finally include main env, for which there is no tag
[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{_,}$_.sh
do
  [[ -e $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" ||
  $LOG alert ":ucbuild[$$]:env-pack" "Failure resolving base env" \
    "E$?:base=${ENV_BASE-(unset)}:pend=${ENV_PEND-(unset)}" ${_E_noenv:-123} ||
      return

[[ ! ${ENV_PEND+set} ]] || $LOG alert ":ucbuild[$$]:env-pack" \
  "Expected complete env" "pending:$ENV_PEND" ${_E_noenv:-123} || return

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info ":ucbuild[$$]:env-pack" "Local env loading..."

# Boilerplate end:

[[ ${PACK_NAME+set} && ${PACK_VER+set} ]] || {

  : "${PACK_LABEL:=${APP:?}}"

  : "${PACK_LABEL%\/*}"
  : "${PACK_NAME:=${_,,}}"

  : "${PACK_LABEL#*\/}"
  : "${PACK_VER:=${_,,}}"
}

: "${PACK_ID:=${PACK_NAME//[^A-Za-z0-9+-]}}"

: "${PACK_NS:=${PACK_ID//[^A-Za-z0-9_]}}"
#
