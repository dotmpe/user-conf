#!/usr/bin/env bash

case " ${ENV_BASE-} " in ( *" pack "* )
  $LOG alert :env-pack "Loop detected" \
    "base=${ENV_BASE-(unset)},pending=${ENV_PEND-(unset)}" ${_E_ifenv:-121}
;; esac

: "${EWD:=${REDO_BASE:-${CWD:-${PWD?}}}}" # Define: env-working-dir

! [[ ${ENV_PEND+set} ]] || {
  [[ ${ENV_PEND%% *} = pack ]] || exit 121
  [[ ${#ENV_PEND} = 4 ]] && unset ENV_PEND || ENV_PEND=${ENV_PEND:5}
}

ENV_BASE=${ENV_BASE-}${ENV_BASE+ }pack

# Continue env chain or finally include main env, for which there is no tag
[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{_,}$_.sh
do
  [[ -s $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" && unset __ ||
  $LOG alert ":next" "At env-pack" "E$?:pending=${ENV_PEND-(unset)}" ${_E_noenv:-123}

[[ ! ${ENV_PEND+set} ]] ||
  $LOG alert ":env-pack" "Expected complete env" "pending: $ENV_PEND" ${_E_noenv:-123}

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info :env-pack "Package env loading..."

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
