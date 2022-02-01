#!/bin/sh

{ cat <<EOM
export LOG=\$PWD/tools/sh/log.sh
export TERM=xterm-256color
export USER=circleci
export COLORIZE=1
export UC_PROFILE_LOG_FILTERS=colorize
export UC_LOG_LEVEL=7
export STDLOG_UC_ANSI=1
export STDLOG_UC_LEVEL=7
EOM
} > ~/.profile
mkdir -vp ~/.local/lib
ln -s ~/project ~/.local/lib/user-conf
{ cat <<EOM
. ~/.profile
set -euTEo pipefail
shopt -s extdebug
. ./script/bash-uc.lib.sh
trap bash_uc_errexit ERR
EOM
} > test-env.sh

#
