#!/usr/bin/env bash

set -e

test -z "$Build_Debug" || set -x

test -z "$Build_Deps_Default_Paths" || {

  test -n "$SRC_PREFIX" || {
    test -w /src/ \
      && SRC_PREFIX=/src/ \
      || SRC_PREFIX=$HOME/build
  }

  test -n "$PREFIX" || {
    test -w /usr/local/ \
      && PREFIX=/usr/local/ \
      || PREFIX=$HOME/.local
  }
}

test -n "$sudo" || sudo=
test -z "$sudo" || pref="sudo $pref"
test -z "$dry_run" || pref="echo $pref"

test -w /usr/local || {
  test -n "$sudo" || pip_flags=--user
  test -n "$sudo" || py_setup_f="--user"
}


test -n "$SRC_PREFIX" || {
  echo "Not sure where checkout"
  exit 1
}

test -n "$PREFIX" || {
  echo "Not sure where to install"
  exit 1
}

test -d $SRC_PREFIX || ${pref} mkdir -vp $SRC_PREFIX
test -d $PREFIX || ${pref} mkdir -vp $PREFIX



install_bats()
{
  echo "Installing bats"
  test -n "$BATS_BRANCH" || BATS_BRANCH=master
  test -n "$BATS_REPO" || BATS_REPO=https://github.com/dotmpe/bats.git
  test -n "$BATS_BRANCH" || BATS_BRANCH=master
  test -d $SRC_PREFIX/bats || {
    git clone $BATS_REPO $SRC_PREFIX/bats || return $?
  }
  (
    cd $SRC_PREFIX/bats
    git checkout $BATS_BRANCH
    ${pref} ./install.sh $PREFIX
  )
}

install_git_versioning()
{
  git clone https://github.com/dotmpe/git-versioning.git $SRC_PREFIX/git-versioning
  ( cd $SRC_PREFIX/git-versioning && ./configure.sh $PREFIX && ENV=production ./install.sh )
}

install_docopt()
{
  test -n "$install_f" || install_f="$py_setup_f"
  git clone https://github.com/dotmpe/docopt-mpe.git $SRC_PREFIX/docopt-mpe
  ( cd $SRC_PREFIX/docopt-mpe \
      && git checkout 0.6.x \
      && $pref python ./setup.py install $install_f )
}


main_entry()
{
  test -n "$1" || set -- all

  case "$1" in all|project|test|git )
      git --version >/dev/null || {
        echo "Sorry, GIT is a pre-requisite"; exit 1; }
    ;; esac

  case "$1" in all|pip|python )
      which pip >/dev/null || {
        cd /tmp/ && wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py; }
      pip install -r requirements.txt
    ;; esac

  case "$1" in all|build|test|sh-test|bats )
      test -x "$(which bats)" || { install_bats || return $?; }
    ;; esac

  case "$1" in all|dev|build|check|test|git-versioning )
      test -x "$(which git-versioning)" || {
        install_git_versioning || return $?; }
    ;; esac

  case "$1" in python|project|docopt)
      # Using import seems more robust than scanning pip list
      python -c 'import docopt' || { install_docopt || return $?; }
    ;; esac


  echo "OK. All pre-requisites for '$1' checked"
}

test "$(basename $0)" = "install-dependencies.sh" && {
  test -n "$1" || set -- all
  while test -n "$1"
  do
    main_entry "$1" || exit $?
    shift
  done
} || printf ""

# Id: user-conf/0.0.1-dev install-dependencies.sh
