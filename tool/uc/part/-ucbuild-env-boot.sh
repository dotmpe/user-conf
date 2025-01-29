#!/usr/bin/env bash

## ucbuild:env-boot Env script wrapper

# env-boot is a helper for env-bash and others that want an function to be
# invoked at the end, but only after sourcing all pending parts.

# Boilerplate (derived from env-local)
! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info ":ucbuild[$$]:env-boot" "Bootable env loading..."

case " ${ENV_BASE-} " in ( *" boot "* )
  $LOG alert ":ucbuild[$$]:env-boot" "Loop detected" \
    "base=${ENV_BASE-(unset)},pending=${ENV_PEND-(unset)}" ${_E_ifenv:-121} ||
      return
;; esac

[[ ${ENV_PEND+set} ]] ||
  $LOG alert ":ucbuild[$$]:env-boot" "Unverified env" "" ${_E_ifenv:-121} ||
    return

[[ ${ENV_PEND%% *} = boot ]] || return ${_E_ifenv:-121}
[[ ${#ENV_PEND} = 4 ]] && unset ENV_PEND || ENV_PEND=${ENV_PEND:5}

ENV_BASE=${ENV_BASE-}${ENV_BASE+ }boot

[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{_,}$_.sh
do
  [[ -e $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" ||
  $LOG alert ":ucbuild[$$]:env-boot" "Failure resolving base env" \
    "E$?:base=${ENV_BASE-(unset)}:pend=${ENV_PEND-(unset)}" ${_E_noenv:-123} ||
      return

[[ ! ${ENV_PEND+set} ]] || $LOG alert ":ucbuild[$$]:env-boot" \
  "Expected complete env" "pending:$ENV_PEND" ${_E_noenv:-123} || return

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info ":ucbuild[$$]:env-boot" "Bootable env ready"

# Boilerplate end:

#[[ ${BASH_SOURCE[0]} = .env-bash.sh ]] &&
#  || {
#    declare -p BASH_SOURCE >&2
#  }
# XXX: should rewrite this to use some limited seeding of a boot script, build
# cache etc.
#[[ ! ${ENV_BOOT-} ]] ||
[[ ! ${ENV_INIT+set} ]] && {
  $LOG warn :ucbuild:env-boot "Boot env group is included but no init handler was specified"
} || {

  "${ENV_INIT:?}" || {
    test 127 -eq $? && {
      $LOG error "" "Env boot handler expected" "Not-Found:ENV_INIT=$ENV_INIT" $_
      return
    } ||
      $LOG error "" "Unexpected env boot status" "E$_:ENV_INIT=$ENV_INIT" $_
  }
}

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG debug ":ucbuild[$$]:env-boot" "Bootable env done"
#  $LOG debug :env-boot "Bootable env done"
