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

# This env trigger depends on uc-env

#uc-env -q uc:env && {
if_ok "$(declare -F uc_env)" && {
  if_ok "$(declare -F uc:env:bash)" && {
    uc_env +continue ||
      $LOG info ":ucbuild[$$]:bash-env" "Failed starting from compiled env" \
        "E$?" ${_E_ifenv:-121} || ${uc_stat:-exit} $?
  } || {
    declare -gA uc_env{,_{parts,types}}
    declare -ga uc_env_exports
    # XXX: dyanmic setup disabled for now, see local-env
  }
} || {
  # XXX: we need to fork the entire process to get env
  uc-env -R uc:env || exit $?
}

# If the right env is already provided, we just run the
# start hooks.
#uc_env -qs local base=${EWD:?} && {
#  uc_env :hooks:start
#  return
#}
# This can happen if another script takes control of the
# env, or if a parent shell loaded a static or cached slice.
#for __static in ${EWD:?}/{,.}{,_}static.sh
#do
#  declare -p __static
#  #[[ -e $static ]]
#done


# To get the local env, we need data of which we don't know
# yet. The key here is we need a pending attribute for the
# current base, which is then used as the us env squence below.

! "${DEBUG:-false}" || {
  declare -x US_DEBUG=${US_DEBUG:-false}
  declare -x UC_DEBUG=${UC_DEBUG:-false}
}

#: "${ENV_PEND=local}"

: "${BASH_UC_SCRIPTNAME:=Local}"
: "${BASH_UC_SCRIPTTAG:=$0[$$]:bash-env}"
: "${UC_LOG_BASE:=$BASH_UC_SCRIPTTAG}"
declare -x UC_LOG_BASE

declare -x OS_{HOSTNAME,UNAME}


# XXX: would like to return to mode for DIAG after env has completed
OLDSET=$-
set -eETu
shopt -s extdebug

{ ! "${DIAG:-false}" && ! "${STRICT:-false}"
} ||
  set -eETuo pipefail

! "${DIAG:-false}" || shopt -s extdebug


! "${VERBOSE:-false}" || ! "${DEBUG:-false}" ||
  $LOG info :ucbuild:bash-env "Bash env trigger started..."

# NOTE: trigger script for BASH_ENV Bash shell special variable.

# Not bothering adding bash to env tags for now, just boot for whatever env-pend
# is set or default.
[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{_,}$_.sh
do
  [[ -e $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" ||
  $LOG alert ":ucbuild[$$]:bash-env" "Failure resolving base env" \
    "E$?:base=${ENV_BASE-(unset)}:pend=${ENV_PEND-(unset)}" ${_E_noenv:-123}


# Export env and env metadata

#for __env_key in "${uc_env_exports[@]}"
#do
#  declare -x${uc_env_types["$__env_key"]-} $__env_key
#done

# XXX: cant think of way to do this incrementally, so need to dump everything
#if_ok "$(declare -f uc:env:bash)" && {
#  : "${_#uc:env:bash ()$'*\n\{*\n'}" &&
#  : "${_%\}}  : :#: Local-env append: "
#} || {
#  : "  : :#: Local-env root: "
#}
eval "uc:env:bash () {
  declare -ga uc_env_exports
  uc_env_exports=( ${uc_env_exports[*]} )
  declare -gA uc_env_parts
  $( for __env_key in "${!uc_env_parts[@]}"
    do
      echo "uc_env_parts[\"$__env_key\"]=${uc_env_parts["$__env_key"]@Q}"
    done)
  declare -gA uc_env_types
  $( for __env_key in "${!uc_env_types[@]}"
    do
      echo "uc_env_types[\"$__env_key\"]=${uc_env_types["$__env_key"]@Q}"
    done)
}"
declare -xf uc:env:bash

: "${ENV_PEND=local}"
declare +x ENV_PEND
>&2 declare -p ENV_PEND

#
