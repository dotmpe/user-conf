#!/usr/bin/env bash

## ucbuild:env-boot Env script wrapper

# env-boot is a helper for env-bash and others that want an function to be
# invoked at the end, but only after sourcing all pending parts.

# Boilerplate (derived from env-local)
case " $ENV_BASE " in ( *" boot "* )
  $LOG alert :env-boot "Loop detected" \
    "base=${ENV_BASE-(unset)},pending=${ENV_PEND-(unset)}" ${_E_ifenv:-121}
;; esac

: "${EWD:=${REDO_BASE:-${CWD:-${PWD?}}}}" # Copy: env-working-dir

[[ ${ENV_PEND+set} ]] && {
  [[ ${ENV_PEND%% *} = boot ]] || exit ${_E_envif:-121}
  [[ ${#ENV_PEND} = 4 ]] && unset ENV_PEND || ENV_PEND=${ENV_PEND:5}
} || {
  ENV_PEND=${ENV_PEND_DEFAULT:-local}
}

ENV_BASE=${ENV_BASE-}${ENV_BASE+ }boot

# Continue env chain, at either 'local' or something else
[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{,_}$_.sh
do
  [[ -s $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" && unset __ ||
    $LOG alert "" "At env-boot" "E$?:pending=${ENV_PEND-(unset)}" ${_E_noenv:-123}

[[ ! ${ENV_PEND+set} ]] ||
  $LOG alert ":env-boot" "Expected complete env" "pending: $ENV_PEND" ${_E_noenv:-123}

# Boilerplate end:

#[[ ${BASH_SOURCE[0]} = .env-bash.sh ]] &&
#  || {
#    declare -p BASH_SOURCE >&2
#  }
# XXX: should rewrite this to use some limited seeding of a boot script, build
# cache etc.
#[[ ! ${ENV_BOOT-} ]] ||
[[ ! ${ENV_INIT-} ]] || {

  "${ENV_INIT:?}" || {
    test 127 -eq $? && {
      $LOG error "" "Env boot handler expected" "Not-Found:ENV_INIT=$ENV_INIT" $_
      return
    } ||
      $LOG error "" "Unexpected env boot status" "E$_:ENV_INIT=$ENV_INIT" $_
  }
}
