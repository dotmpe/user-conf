#!/usr/bin/env bash

# annex-p-build:env

# Boilerplate (derived from env-local)

case " $ENV_BASE " in ( *" build "* )
  $LOG alert :env-build "Loop detected" \
    "base=${ENV_BASE-(unset)},pending=${ENV_PEND-(unset)}" ${_E_ifenv:-121}
;; esac

: "${EWD:=${REDO_BASE:-${CWD:-${PWD?}}}}" # Copy: env-working-dir

! [[ ${ENV_PEND+set} ]] || {
  [[ ${ENV_PEND%% *} = build ]] || exit 121
  [[ ${#ENV_PEND} = 5 ]] && unset ENV_PEND || ENV_PEND=${ENV_PEND:6}
}

ENV_BASE=${ENV_BASE-}${ENV_BASE+ }build

# XXX: this has different sh-mode and env-init from normal .env-local sequence?

set -euo pipefail &&

# Continue env chain or finally include main env, for which there is no tag
[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{,_}$_.sh
do
  [[ -s $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" && unset __ ||
  $LOG alert ":next" "At env-build" "E$?:pending=${ENV_PEND-(unset)}" ${_E_noenv:-123}

[[ ! ${ENV_PEND+set} ]] ||
  $LOG alert ":env-build" "Expected complete env" "pending: $ENV_PEND" ${_E_noenv:-123}

# Boilerplate end:

# The env-build also inserts a default Env-Init that env-boot would pick up
: "${ENV_INIT:=${PACK_ID//[^A-Za-z0-9_]/_}_env_${ENV_ID:?}_init}"
