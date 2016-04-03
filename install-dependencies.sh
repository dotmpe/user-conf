#!/usr/bin/env bash

set -e

test -z "$Build_Debug" || set -x

test -z "$Build_Deps_Default_Paths" || {
  test -n "$SRC_PREFIX" || SRC_PREFIX=$HOME/build
  test -n "$PREFIX" || PREFIX=$HOME/.local
}

test -n "$sudo" || sudo=

test -n "$SRC_PREFIX" || {
  echo "Not sure where checkout"
  exit 1
}

test -n "$PREFIX" || {
  echo "Not sure where to install"
  exit 1
}

test -d $SRC_PREFIX || ${sudo} mkdir -vp $SRC_PREFIX
test -d $PREFIX || ${sudo} mkdir -vp $PREFIX


install_bats()
{
  echo "Installing bats"
  pushd $SRC_PREFIX
  git clone https://github.com/sstephenson/bats.git
  cd bats
  ${sudo} ./install.sh $PREFIX
  popd
}

install_git_versioning()
{
  git clone https://github.com/dotmpe/git-versioning.git $SRC_PREFIX/git-versioning
  ( cd $SRC_PREFIX/git-versioning && ./configure.sh $HOME/.local && ENV=production ./install.sh )
}

install_docopt()
{
  git clone https://github.com/dotmpe/docopt-mpe.git $SRC_PREFIX/docopt-mpe
  ( cd $SRC_PREFIX/docopt-mpe && git checkout 0.6.x && python /src/docopt-mpe/setup.py install )
}


main_entry()
{
  test -n "$1" || set -- '*'

  case "$1" in '*'|project|git )
      git --version >/dev/null || { echo "Sorry, GIT is a pre-requisite"; exit 1; }
    ;; esac

  case "$1" in '*'|build|test|sh-test|bats )
      test -x "$(which bats)" || install_bats || return $?
    ;; esac

  case "$1" in '*'|dev|build|check|test|git-versioning )
      test -x "$(which git-versioning)" || install_git_versioning || return $?
    ;; esac

  case "$1" in '*'|project|docopt )
      pip --version >/dev/null || { echo "Sorry, PIP is a pre-requisite"; exit 1; }
      pip list | grep -q '^docopt' || {
        #pip install docopt-mpe
        install_docopt
      }
    ;; esac


  case "$1" in '*'|project|dev|build|test|check|\
      sh-test|git|git-versioning|bats|python|docopt ) ;;
    *)
      echo "No such known dependency '$1'"
      exit 2
    ;; esac

  echo "OK. All pre-requisites for '$1' checked"
}

test "$(basename $0)" = "install-dependencies.sh" && {
  main_entry $@ || exit $?
}

# Id: user-conf
