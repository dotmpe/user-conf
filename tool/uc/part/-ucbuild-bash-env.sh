#!/usr/bin/env bash

## ucbuild:bash-env Bash env wrapper (boilerplate)

# Using BASH_ENV its possible to let every subsequent Bash (sub)process auto-
# source given file. This wrapper unsets the var so that only one subprocess
# 'layer' has responsibility for further setup and env export. This then
# continues bootstrap using the sequence in ENV_PEND{,_DEFAULT} or default 'boot
# local'.

# This is a separate boilerplate from the other ucbuild:env-* parts.

# Stop subshells from restarting this script. We'll export any bits when needed.
unset BASH_ENV 2>/dev/null || true

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
