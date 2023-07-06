#!/bin/sh

mkdir -vp ~/src/{bitbucket.org,github.com}/dotmpe

# XXX: bb needs auth
U_S=$HOME/src/github.com/user-scripts
#export U_S=$HOME/src/bitbucket.org/user-scripts

{ cat <<EOM
# Added by Uc:tools/ci/setup.sh <$0> on $(date --iso=min)"
export verbosity=7
export TERM=xterm-256color
export USER=circleci
export COLORIZE=1
export UC_PROFILE_LOG_FILTERS=colorize
export UC_LOG_LEVEL=7
export STDLOG_UC_ANSI=1
export STDLOG_UC_LEVEL=7
export XDG_RUNTIME_HOME=\$PWD/build/runtime-data
export XDG_CACHE_HOME=\$PWD/build/cache
export UCONF=$HOME/.conf
export U_C=$HOME/project
export U_S=$U_S
export PATH=\$PATH:\$U_S/src/sh/lib:\$U_S/src/bash/lib:\$U_S/commands:\$U_S/contexts
export PATH=\$PATH:\$U_C/script:\$U_C/script/context
EOM
} >| ~/.profile

# Current project is user-conf main repo
test -e ~/.local/lib/user-conf || {
  mkdir -vp ~/.local/lib
  ln -s ~/project ~/.local/lib/user-conf
}

# Get user-scripts main repo
test -e "$U_S" || {
  git clone https://github.com/dotmpe/user-scripts -b r0.0 "$U_S"
}

{ cat <<EOM
. ~/.profile

. \${U_S:?}/tools/sh/parts/fnmatch.sh
. \${U_S:?}/tools/sh/parts/sh-mode.sh
#sh_mode build
sh_mode strict dev log-init

\$LOG info :test-env "Sourcing uc-profile.lib"
. \${U_C:?}/script/uc-profile.lib.sh
export -f uc_fun uc_debug

\$LOG info :test-env "Loading shell helpers"
. \${U_C:?}/script/shell-uc.lib.sh && shell_uc_lib__load && shell_uc_lib__init

\$LOG info :test-env "Loading shell lib helpers"
. \${U_C:?}/script/lib-uc.lib.sh && lib_uc_lib__load && lib_uc_lib__init
export -f lib_{uc_,}{exists,load,loaded,init,require}

\$LOG info :test-env "Starting log env"
sh_mode log-uc-start
\$LOG notice :test-env "Loaded" "0:\$0 -:\$- #:\$# *:\$*"
EOM
} >| ./.test-env.sh

#
