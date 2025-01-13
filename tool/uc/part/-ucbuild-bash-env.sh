#!/usr/bin/env bash

## ucbuild:bash-env Bash env wrapper (boilerplate)

# Using BASH_ENV its possible to let every subsequent Bash (sub)process auto-
# source given file. This wrapper unsets the var so that only one subprocess
# 'layer' (the current session) bears responsibility for further setup and env
# export. This is also because BASH_ENV is not really suitable for dynamic
# script command config. Upon load this continues bootstrap using the sequence
# in ENV_PEND{,_DEFAULT} or default 'boot local'.

# This is a separate boilerplate from the other ucbuild:env-* parts, but
# essential to let Bash autoload that sequence (including calling a function
# $ENV_INIT, in the 'env-boot' group) at start. Note however that this is before
# the actual script command. The actual command for the current session seems to
# be wholly unaccessible/unknown at this point. So dynamic script setup is only
# possible here by explicit export/local env, such as ENV_PEND. More practical
# is to export or include a function (with 'env-static') and call a specific
# initialization routine (explicitly) at the start of the command script.

# Stop subshells from restarting this script. We'll export any bits when needed.
unset BASH_ENV 2>/dev/null || true

! "${DEBUG:-false}" || {
    declare -x US_DEBUG=${US_DEBUG:-false}
    declare -x UC_DEBUG=${UC_DEBUG:-false}
}

! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info :bash-env "Bash env loading..."

# Continue with next env script (at root of project, ie. regardless where we
# started)
# XXX: could also take basedir of current source, but that could interfere with
# re-use by symlinking.
: "${EWD:=${REDO_BASE:-${CWD:-${PWD?}}}}" # Copy: env-working-dir

# Not bothering adding bash to env tags for now, just boot for whatever env-pend
# is set or default.
: "${ENV_PEND=${ENV_PEND_DEFAULT:-boot local}}"
#: "env-${ENV_PEND%% *}"
[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{_,}$_.sh
do
  [[ -s $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" && unset __ ||
    $LOG alert "" "At bash-env" "E$?:pending=${ENV_PEND-(unset)}" ${_E_noenv:-123}
