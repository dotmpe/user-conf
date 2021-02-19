#!/bin/sh

set -e

stderr_()
{
  echo "$log_pref$1" >&2
  test -z "$2" || exit $2
}

test -z "$Build_Deps_Default_Paths" || {

  test -n "$SRC_PREFIX" || {
    test -w /src/ \
      && SRC_PREFIX=/src/local \
      || SRC_PREFIX=$HOME/build
  }

  test -n "$PREFIX" || {
    test -w /usr/local/ \
      && PREFIX=/usr/local/ \
      || PREFIX=$HOME/.local
  }

  stderr_ "Setting default paths: SRC_PREFIX=$SRC_PREFIX PREFIX=$PREFIX"
}

test -n "$SRC_PREFIX" ||
  stderr_ "Not sure where to checkout (SRC_PREFIX missing)" 1

test -n "$PREFIX" ||
  stderr_ "Not sure where to install (PREFIX missing)" 1


test -d $SRC_PREFIX || ${pref} mkdir -vp $SRC_PREFIX
test -d $PREFIX || ${pref} mkdir -vp $PREFIX


install_Bash ()
{
  test -x "$(which bash)" || stderr_ "Sorry, Bash is required" 1
}


install_Basher ()
{
  test -n "${BASHER_REPO-}" || BASHER_REPO=https://github.com/dotmpe/basher.git
  test -n "${BASHER_BRANCH-}" || BASHER_BRANCH=feature/better-package-env
  test -n "${BASHER_BASE-}" || BASHER_BASE=$HOME/.basher
  test -n "$BASHER_BASE" || {
    BASHER_BASE="$SRC_PREFIX/$(basename "$(dirname "$BASHER_REPO")")/$(basename "$BASHER_REPO" .git)"
  }

  test -d "$BASHER_BASE" || {
    git clone "$BASHER_REPO" "$BASHER_BASE" || return
  }
  (
    cd "$BASHER_BASE" &&
    git checkout "$BASHER_BRANCH"
  ) || return
  export PATH=$BASHER_BASE/bin:$BASHER_BASE/cellar/bin:$PATH
}


uninstall_Basher ()
{
  test -n "${BASHER_BASE-}" || BASHER_BASE=$HOME/.basher
  rm -rf "$BASHER_BASE"
}


install_Bats ()
{
  test -n "${BATS_REPO-}" || BATS_REPO=https://github.com/dotmpe/bats-core.git
  test -n "${BATS_BRANCH-}" || BATS_BRANCH=master
  test -n "${BATS_BASE-}" || BATS_BASE=$SRC_PREFIX/dotmpe/bats-core
  test -n "$BATS_BASE" || {
    BATS_BASE="$SRC_PREFIX/$(basename "$(dirname "$BATS_REPO")")/$(basename "$BATS_REPO" .git)"
  }

  test -d "$BATS_BASE" || {
    git clone "$BATS_REPO" "$BATS_BASE" || return
  }
  (
    cd "$BATS_BASE" &&
    git checkout "$BATS_BRANCH"
  ) || return
  ( cd $BATS_BASE && ${pref} ./install.sh $PREFIX && git clean -dfx )

}


uninstall_Bats ()
{
  test -n "${BATS_BASE-}" || BATS_BASE=$SRC_PREFIX/dotmpe/bats-core
  rm -rf "$BATS_BASE"
}


install_Git ()
{
  test -x "$(which git)" || stderr_ "Sorry, Git is required" 1
}


install_git_versioning ()
{
  test -n "${GIT_VERSIONING_REPO-}" || GIT_VERSIONING_REPO=https://github.com/dotmpe/git-versioning.git
  test -n "${GIT_VERSIONING_BRANCH-}" || GIT_VERSIONING_BRANCH=master
  test -n "${GIT_VERSIONING_BASE-}" || GIT_VERSIONING_BASE=
  test -n "$GIT_VERSIONING_BASE" || {
    GIT_VERSIONING_BASE="$SRC_PREFIX/$(basename "$(dirname "$GIT_VERSIONING_REPO")")/$(basename "$GIT_VERSIONING_REPO" .git)"
  }

  test -d "$GIT_VERSIONING_BASE" || {
    git clone "$GIT_VERSIONING_REPO" "$GIT_VERSIONING_BASE" || return
  }
  (
    cd "$GIT_VERSIONING_BASE" &&
    git checkout "$GIT_VERSIONING_BRANCH"
  ) || return
  ( cd $GIT_VERSIONING_BASE && ${pref} ./install.sh $PREFIX && git checkout . && git clean -dfx )
}


uninstall_git_versioning ()
{
  test -n "${GIT_VERSIONING_BASE-}" || GIT_VERSIONING_BASE=
  rm -rf "$GIT_VERSIONING_BASE"
}


install_User_Conf_dev ()
{
  test -n "${USER_CONF_DEV_REPO-}" || USER_CONF_DEV_REPO=https://github.com/dotmpe/user-conf.git
  test -n "${USER_CONF_DEV_BRANCH-}" || USER_CONF_DEV_BRANCH=r0.2
  test -n "${USER_CONF_DEV_BASE-}" || USER_CONF_DEV_BASE=
  test -n "$USER_CONF_DEV_BASE" || {
    USER_CONF_DEV_BASE="$SRC_PREFIX/$(basename "$(dirname "$USER_CONF_DEV_REPO")")/$(basename "$USER_CONF_DEV_REPO" .git)"
  }

  test -d "$USER_CONF_DEV_BASE" || {
    git clone "$USER_CONF_DEV_REPO" "$USER_CONF_DEV_BASE" || return
  }
  (
    cd "$USER_CONF_DEV_BASE" &&
    git checkout "$USER_CONF_DEV_BRANCH"
  ) || return
  basher link $SRC_PREFIX/dotmpe/user-conf dotmpe/user-conf
}


uninstall_User_Conf_dev ()
{
  test -n "${USER_CONF_DEV_BASE-}" || USER_CONF_DEV_BASE=
  rm -rf "$USER_CONF_DEV_BASE"
}


install_User_Conf_Repo ()
{
  test -n "${USER_CONF_REPO_REPO-}" || USER_CONF_REPO_REPO=https://github.com/dotmpe/user-conf-repo.git
  test -n "${USER_CONF_REPO_BRANCH-}" || USER_CONF_REPO_BRANCH=master
  test -n "${USER_CONF_REPO_BASE-}" || USER_CONF_REPO_BASE=$HOME/.conf
  test -n "$USER_CONF_REPO_BASE" || {
    USER_CONF_REPO_BASE="$SRC_PREFIX/$(basename "$(dirname "$USER_CONF_REPO_REPO")")/$(basename "$USER_CONF_REPO_REPO" .git)"
  }

  test -d "$USER_CONF_REPO_BASE" || {
    git clone "$USER_CONF_REPO_REPO" "$USER_CONF_REPO_BASE" || return
  }
  (
    cd "$USER_CONF_REPO_BASE" &&
    git checkout "$USER_CONF_REPO_BRANCH"
  ) || return
  uc init || return
  uc update
  export PATH=$USER_CONF_REPO_BASE/path/Generic:$USER_CONF_REPO_BASE/path/Linux:$PATH
}


uninstall_User_Conf_Repo ()
{
  test -n "${USER_CONF_REPO_BASE-}" || USER_CONF_REPO_BASE=$HOME/.conf
  rm -rf "$USER_CONF_REPO_BASE"
}


main_install_dependencies () # Tags...
{
  test $# -gt 0 || set -- Basher Bats git-versioning User-Conf-dev User-Conf-Repo
  stderr_ "Running 'install-dependencies $*'"

  for a in $@
  do case "$a" in
  esac; done

  while test $# -gt 0
  do case "$1" in
    Bash )
        test -x "$(which bash)" && {
          type update_Bash >/dev/null 2>&1 || return 0
          update_Bash || return
        } || {
          install_Bash || return
        }
      ;;

    Basher )
        test -x "$(which basher)" && {
          type update_Basher >/dev/null 2>&1 || return 0
          update_Basher || return
        } || {
          install_Basher || return
        }
      ;;

    Bats )
        test -x "$(which bats)" && {
          type update_Bats >/dev/null 2>&1 || return 0
          update_Bats || return
        } || {
          install_Bats || return
        }
      ;;

    Git )
        test -x "$(which git)" && {
          type update_Git >/dev/null 2>&1 || return 0
          update_Git || return
        } || {
          install_Git || return
        }
      ;;

    git-versioning )
        test -x "$(which git-versioning)" && {
          type update_git_versioning >/dev/null 2>&1 || return 0
          update_git_versioning || return
        } || {
          install_git_versioning || return
        }
      ;;

    User-Conf-dev )
        test -x "$(which user-conf-dev)" && {
          type update_User_Conf_dev >/dev/null 2>&1 || return 0
          update_User_Conf_dev || return
        } || {
          install_User_Conf_dev || return
        }
      ;;

    User-Conf-Repo )
        test -x "$(which user-conf-repo)" && {
          type update_User_Conf_Repo >/dev/null 2>&1 || return 0
          update_User_Conf_Repo || return
        } || {
          install_User_Conf_Repo || return
        }
      ;;

    * ) stderr_ "Unknown tool '$a'" 1 ;;
    esac
    stderr_ "OK. Pre-requisites for '$1' checked"
    shift
  done
}


main_load ()
{
  #test -x "$(which tput)" && ... TODO: colorize install-dependencies
  log_pref="[install-dependencies] "

  stderr_ "Loaded (pwd:$PWD, *:$*)"
}


case "$(basename "$0" .sh)" in

    install-dependencies )
      main_load && main_install_dependencies "$@" ;;

esac

# Generated at 2021-02-16T20:52+01:00 using /home/hari/.local/composure/Tools/install-dependencies.scr
# Id: user-conf/0.2.0-dev install-dependencies.sh
