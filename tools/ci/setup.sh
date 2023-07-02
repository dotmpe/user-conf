#!/bin/sh

{ cat <<EOM
# Added by Uc:tools/ci/setup.sh <$0> on $(date --iso=min)"
export LOG=\$PWD/tools/sh/log.sh
export TERM=xterm-256color
export USER=circleci
export COLORIZE=1
export UC_PROFILE_LOG_FILTERS=colorize
export UC_LOG_LEVEL=7
export STDLOG_UC_ANSI=1
export STDLOG_UC_LEVEL=7
export XDG_RUNTIME_HOME=\$PWD/build/runtime-data
export XDG_CACHE_HOME=\$PWD/build/cache
export U_C=$HOME/project
export U_S=$HOME/src/bitbucket.org/user-scripts
EOM
#export U_S=$HOME/src/github.com/user-scripts
} > ~/.profile

test -e ~/.local/lib/user-conf || {
  mkdir -vp ~/.local/lib
  ln -s ~/project ~/.local/lib/user-conf
}

{ cat <<EOM
. ~/.profile
set -euTEo pipefail
shopt -s extdebug
. ./script/bash-uc.lib.sh
trap bash_uc_errexit ERR
EOM
} > test-env.sh

ls -la ~/.local/{etc,lib,usr,var}
echo

test -e ~/src/bitbucket.org/user-scripts || {
  mkdir -vp ~/src/{bitbucket.org,github.com}/dotmpe
  #git clone https://github.com/dotmpe/user-scripts -b r0.0 \
  #  ~/src/github.com/dotmpe/user-scripts
  #git clone git@bitbucket.org:dotmpe/user-scripts -b r0.0 \
  git clone https://bitbucket.org/dotmpe/user-scripts.git -b r0.0 \
    ~/src/bitbucket.org/dotmpe/user-scripts
}

#
