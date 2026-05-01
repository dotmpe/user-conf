# This env trigger depends on uc-env or a minimal user-script env being
# established first.

[[ ${PS1:+set} ]] || uc_stat=exit

#uc-env -q uc:env && uc_env_start ||
uc_env +continue || return

: "${ENV_PEND=local}"
#declare +x ENV_PEND

# XXX: would like to return to mode for DIAG after env has completed
#OLDSET=$-
#set -eETu
#shopt -s extdebug

! ((VERBOSE)) ||
  $LOG info :ucbuild:local-env "Local env trigger started..."

APP_ID=uconfmpe

# XXX: interactive user shell session params...
PS1_ATTR=pyvenv\ keystat\ mail\ u-s\ visual\ debug\ envsrc

#export BASH_ENV=${EWD:?}/.bash-env.sh
export BUILD_TARGETS=${EWD:?}/.build-targets+4524.list

export ENV_PEND_DEFAULT=boot\ static\ local
export ENV_PEND_BUILD=boot\ static\ build\ local
#export ENV_INIT=${APP_ID:?}_static_init
export ENV_INIT=uconf_static_init
#export ENV_STATIC_INC=${APP_ID:?}-local.static.inc
export ENV_STATIC_INC=uconf-build

compo_inc_sh=${C_INC:?}/.meta/cache/includes,composure.bash

export METADIR=${EWD:?}/.meta

: "${A:=@build:}"

[[ ${ENV_PEND+set} ]] && : "env-${ENV_PEND%% *}" || : "env"
for __ in ${EWD:?}/{,.}{_,}$_.sh
do
  [[ -e $__ ]] && break || continue
done && [[ -s $__ ]] && . "$__" ||
  $LOG alert ":ucbuild[$$]:local-env" "Failure resolving base env" \
    "E$?:base=${ENV_BASE-(unset)}:pend=${ENV_PEND-(unset)}" ${_E_noenv:-123}

# Append metadata and run exports
uc_env +start
