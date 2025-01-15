#!/usr/bin/env bash

## ucbuild:env-local Env script for user-script shell boot routine

# 'env-local' is the simplest ENV_{PEND+BASE} handler, including just the local
# .env.sh, or whatever is pending. Its a template of boilerplate that can be
# copied and appended to in other .env-*.sh files.

# For example, a build system could pick up script and env this way, and
# user scripts as well.
# XXX: however may want a few build env helpers. See uc-build ucbuild_env*

#us-env -r -V EWD

# Boilerplate that uses this script should copy (and update from) below

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG debug :env-local "Local env starting..."

case " ${ENV_BASE-} " in ( *" local "* )
  $LOG alert :env-local "Loop detected" \
    "base=${ENV_BASE-(unset)},pending=${ENV_PEND-(unset)}" ${_E_ifenv:-121}
;; esac

: "${EWD:=${REDO_BASE:-${CWD:-${PWD?}}}}" # Define: env-working-dir

# To structure (pre-env) boilerplate a bit, two vars ENV_{BASE,PEND} are
# introduced to track what has been sourced already and whats up next
# respectively.

# Each script removes its tag from PEND and adds it to BASE
! [[ ${ENV_PEND+set} ]] || {
  [[ ${ENV_PEND%% *} = local ]] || exit 121
  [[ ${#ENV_PEND} = 5 ]] && unset ENV_PEND || ENV_PEND=${ENV_PEND:6}
}

ENV_BASE=${ENV_BASE-}${ENV_BASE+ }local

# Continue env chain or finally include main env, for which there is no tag
[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{_,}$_.sh
do
  [[ -s $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" && unset __ ||
  $LOG alert ":next" "At env-local" "E$?:pending=${ENV_PEND-(unset)}" ${_E_noenv:-123}

[[ ! ${ENV_PEND+set} ]] ||
  $LOG alert ":env-local" "Expected complete env" "pending: $ENV_PEND" ${_E_noenv:-123}

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info :env-local "Local env loading..."

# Boilerplate end:

# Set ENV_{NAME,ID} now as well, so other local doesnt need to

#: "${ENV_WID:=${ENV_NAME//[^A-Za-z0-9_]/_}}"

ENV_NID=${ENV_ID:+${ENV_ID}:}local

: "${ENV_BASE//[-]}"
: "${_// /-}"
: "${ENV_NAME:=${PACK_NAME:-${APP:?env-local: No env-name (dir: $EWD, bases: $_, pending: ${ENV_PEND-unset})}}.${_}}"

#! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
#  $LOG debug :env-local "Local env done"
