#!/bin/sh

set -e

stderr_()
{
  echo "$log_pref$1" >&2
  test -z "$2" || exit $2
}

test -z "$Build_Debug" || set -x

test -z "$Build_Deps_Default_Paths" || {

  test -n "$SRC_PREFIX" || {
    test -w /src/ \
      && SRC_PREFIX=/src \
      || SRC_PREFIX=$HOME/build
  }

  test -n "$PREFIX" || {
    test -w /usr/local/ \
      && PREFIX=/usr/local/ \
      || PREFIX=$HOME/.local
  }

  stderr_ "Setting default paths: SRC_PREFIX=$SRC_PREFIX PREFIX=$PREFIX"
}

test -n "$sudo" || sudo=
test -z "$sudo" || pref="sudo $pref"
test -z "$dry_run" || pref="echo $pref"

test -w /usr/local || {
  test -n "$sudo" || pip_flags=--user
  test -n "$sudo" || py_setup_f="--user"
}

test -n "$SRC_PREFIX" ||
  stderr_ "Not sure where to checkout (SRC_PREFIX missing)" 1

test -n "$PREFIX" ||
  stderr_ "Not sure where to install (PREFIX missing)" 1


test -d $SRC_PREFIX || ${pref} mkdir -vp $SRC_PREFIX
test -d $PREFIX || ${pref} mkdir -vp $PREFIX


install_uc()
{
  stderr_ "Installing User-Conf"
  basher list | grep -qF dotmpe/user-conf || {
    basher install dotmpe/user-conf || return
  }
  test -n "$UCONF_BRANCH" || UCONF_BRANCH=master
  test -n "$UCONF_REPO" || UCONF_REPO=https://github.com/dotmpe/user-conf-repo.git
  test -n "$UCONF_DIR" || UCONF_DIR=~/.conf
  test ! -d "$UCONF_DIR" || stderr_ "$UCONF_DIR exists" 1
  git clone $UCONF_REPO $UCONF_DIR || return
  cd $UCONF_DIR
  git checkout $UCONF_BRANCH -- || return
  uc init || return
  uc update
}


install_bats()
{
  stderr_ "Installing bats"
  test -n "$BATS_VERSION" || BATS_VERSION=master
  test -n "$BATS_REPO" || BATS_REPO=https://github.com/dotmpe/bats-core.git
  local src=$SRC_PREFIX/github.com/$(
    basename $(dirname $BATS_REPO))/$(basename $BATS_REPO .git)
  test -d $src || {
    git clone $BATS_REPO $src || return $?
  }
  (
    cd $src
    git checkout $BATS_VERSION
    ${pref} ./install.sh $PREFIX
    git clean -dfx
  )
}


install_basher ()
{
  test -n "$BASHER_BRANCH" || BASHER_BRANCH=feature/better-package-env
  test -n "$BASHER_REPO" || BASHER_REPO=https://github.com/dotmpe/basher.git
  test -d ~/.basher || {
    git clone https://github.com/dotmpe/basher.git ~/.basher
  }
  (
    cd ~/.basher && git checkout "$BASHER_BRANCH"
  )
  test -x "$(which basher)" &&
    stderr_ "basher installed correctly" || stderr_ "$1: missing basher" 1
}

update_basher ()
{
  test -n "$BASHER_BRANCH" || BASHER_BRANCH=feature/better-package-env
  ( cd ~/.basher
    test "$(git rev-parse --abbrev-ref HEAD)" = "$BASHER_BRANCH" || {
      stderr_ "Basher version is not set to '$BASHER_BRANCH'"
      return 1
    }
    git pull origin "$BASHER_BRANCH"
  )
}


main_install_dependencies () # Tags...
{
  test -n "$1" || set -- all
  stderr_ "Running 'install-dependencies $*'"

  while test $# -gt 0
  do
    case "$1" in all )
      set -- all git bats basher user-conf git-versioning ;; esac

    case "$1" in git )
        git --version >/dev/null ||
          stderr_ "Sorry, GIT is a pre-requisite" 1
      ;; esac

    case "$1" in user-conf )
        test -d ~/.conf || { install_uc || return $?; }
      ;; esac

    case "$1" in bats )
        test -x "$(which bats)" || { install_bats || return $?; }
      ;; esac

    case "$1" in git-versioning )
        test -x "$(which git-versioning)" || {
          install_git_versioning || return $?; }
      ;; esac

    case "$1" in basher )
        test -x "$(which basher)" && {
          update_basher || return
        } || {
          install_basher || return
        }
      ;; esac

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

# Id: user-conf/0.2.0-dev install-dependencies.sh
