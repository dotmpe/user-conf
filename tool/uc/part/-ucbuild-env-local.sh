#!/usr/bin/env bash

## ucbuild:env-local Env script for user-script shell boot routine

# 'env-local' is the simplest ENV_{PEND+BASE} handler, including just the local
# .env.sh, or whatever is pending. Its a template of boilerplate that can be
# copied and appended to in other .env-*.sh files.

# For example, a build system could pick up script and env this way, and
# user scripts as well.
# XXX: however may want a few build env helpers. See uc-build ucbuild_env*

#us-env -r -V EWD
#: "${EWD:=${CWD:-${PWD?}}}" # Define: env-working-dir
#: "${EWD:=${REDO_BASE:-${CWD:-${PWD?}}}}" # Define: build-env-working-dir

# Boilerplate that uses this script should copy (and update from) below

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info ":ucbuild[$$]:env-local" "Local env loading..." \
    "base=${ENV_BASE-(unset)},pending=${ENV_PEND-(unset)}"

case " ${ENV_BASE-} " in ( *" local "* )
  $LOG alert ":ucbuild[$$]:env-local" "Loop detected" \
    "base=${ENV_BASE-(unset)},pending=${ENV_PEND-(unset)}" ${_E_ifenv:-121} ||
      return
;; esac

# To structure (pre-env) boilerplate a bit, two vars ENV_{BASE,PEND} are
# introduced to track what has been sourced already and whats up next
# respectively.

[[ ${ENV_PEND+set} ]] ||
  $LOG alert ":ucbuild[$$]:env-local" "Unverified env" \
    "base=${ENV_BASE-(unset)}" ${_E_ifenv:-121} ||
      return

# Each script removes its tag from PEND and adds it to BASE
[[ ${ENV_PEND%% *} = local ]] || return ${_E_ifenv:-121}
[[ ${#ENV_PEND} = 5 ]] && unset ENV_PEND || ENV_PEND=${ENV_PEND:6}

ENV_BASE=${ENV_BASE-}${ENV_BASE+ }local

# Continue env chain or finally include main env, for which there is no tag
[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{_,}$_.sh
do
  [[ -e $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" ||
  $LOG alert ":ucbuild[$$]:env-local" "Failure resolving base env" \
    "E$?:base=${ENV_BASE-(unset)}:pend=${ENV_PEND-(unset)}" ${_E_noenv:-123} ||
      return

[[ ! ${ENV_PEND+set} ]] || $LOG alert ":ucbuild[$$]:env-local" \
  "Expected complete env" "pending:$ENV_PEND" ${_E_noenv:-123} || return

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info ":ucbuild[$$]:env-local" "Local env complete"

# Boilerplate end:

uc_env_exports+=(
  "ENV_BASE"
  "ENV_NID"
  "ENV_NAME"
)

# Set ENV_{NAME,ID} now as well, so other local doesnt need to

#: "${ENV_WID:=${ENV_NAME//[^A-Za-z0-9_]/_}}"

ENV_NID=${ENV_ID:+${ENV_ID}:}local

: "${ENV_BASE//[-]}"
: "${_// /-}"
: "${ENV_NAME:=${PACK_NAME:-${APP:?env-local: No env-name (dir: $EWD, bases: $_, pending: ${ENV_PEND-unset})}}.${_}}"

# Now that local env is done, we should be able to use it to access the other
# envs implemented for the current directory. The current invocation could
# already be made by a wrapper. Additionally DEV should allow using sources (ie.
# have some cached, generated?)
#
# These all need to be distinguishable. With Env-Local ready,

: "${ENV_TRIGGERS:=local build bash}"
: "${ENV_NAMES:=local pack static boot}"

#[[ "${DEV:-false}" != true ]] && {
#  [[ "${DEBUG:-false}" != true ]] || {
#    false
#  }
#
#} || {
#
#  for __env_name in ${ENV_NAMES:?}
#  do
#    true
#  done && unset __env_name
#
#  for __env_trig in ${ENV_TRIGGERS:?}
#  do
#    true
#  done && unset __env_trig
#}
#
#[[ ! ${PS1:+set} ]] && {
#  # In batch mode, something else is responsible for what to do based on
#  # ENV_NAMES setting. But for local and any already wrapping env the
#  # required command customizations will need to be available somehow for
#  # correct operation.
#  true
#} || {
#  # In the interactive mode the setup can become quite complex. We want to
#  # alias individual commands here, ie. ls, make, anything that is to be
#  # customized for running from the current dir.
#  for __env_name in ${ENV_NAMES:-local}
#  do
#    true
#  done
#}

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG debug ":ucbuild[$$]:env-local" "Local env done"
