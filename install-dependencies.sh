#!/usr/bin/env bash

set -e

stderr()
{
  echo "$1" >&2
  test -z "$2" || exit $2
}

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

  stderr "Setting default paths: SRC_PREFIX=$SRC_PREFIX PREFIX=$PREFIX"
}

test -n "$sudo" || sudo=
test -z "$sudo" || pref="sudo $pref"
test -z "$dry_run" || pref="echo $pref"

test -w /usr/local || {
  test -n "$sudo" || pip_flags=--user
  test -n "$sudo" || py_setup_f="--user"
}

test -n "$SRC_PREFIX" ||
  stderr "Not sure where to checkout (SRC_PREFIX missing)" 1

test -n "$PREFIX" ||
  stderr "Not sure where to install (PREFIX missing)" 1

test -d $SRC_PREFIX || ${pref} mkdir -vp $SRC_PREFIX
test -d $PREFIX || ${pref} mkdir -vp $PREFIX


install_uc()
{
  stderr "Installing User-Conf"
  test -n "$UCONF_BRANCH" || UCONF_BRANCH=master
  test -n "$UCONF_REPO" || UCONF_REPO=https://github.com/dotmpe/bats.git
  test -n "$UCONF_DIR" || UCONF_DIR=~/.conf
  test -d "$UCONF_DIR" || stderr "$UCONF_DIR exists" 1
  git clone https://github.com/dotmpe/user-conf.git $UCONF_DIR
  cd $UCONF_DIR
  git checkout $UCONF_BRANCH --
  ./script/user-conf/init.sh
  ./script/user-conf/update.sh
}

install_bats()
{
  stderr "Installing bats"
  test -n "$BATS_BRANCH" || BATS_BRANCH=master
  test -n "$BATS_REPO" || BATS_REPO=https://github.com/dotmpe/bats.git
  test -d $SRC_PREFIX/bats || {
    git clone $BATS_REPO $SRC_PREFIX/bats || return $?
  }
  (
    cd $SRC_PREFIX/bats
    git checkout $BATS_BRANCH
    ${pref} ./install.sh $PREFIX
  )
}

install_composer()
{
  test -e $PREFIX/bin/composer || {
    curl -sS https://getcomposer.org/installer |
      php -- --install-dir=$PREFIX/bin --filename=composer
  }
  $PREFIX/bin/composer --version
  . ~/.conf/bash/env.sh
  test -x "$(which composer)" ||
    stderr "Composer is installed but not found on PATH! Aborted. " 1
  # XXX: cleanup
  #test -e composer.json && {
  #  test -e composer.lock && {
  #    composer update
  #  } || {
  #    rm -rf vendor || noop
  #    composer install
  #  }
  #} || {
  #  stderr "No composer.json"
  #}
}

install_docopt()
{
  test -n "$install_f" || install_f="$py_setup_f"
  git clone https://github.com/dotmpe/docopt-mpe.git $SRC_PREFIX/docopt-mpe
  ( cd $SRC_PREFIX/docopt-mpe \
      && git checkout 0.6.x \
      && $pref python ./setup.py install $install_f )
}

install_git_versioning()
{
  git clone https://github.com/dotmpe/git-versioning.git $SRC_PREFIX/git-versioning
  ( cd $SRC_PREFIX/git-versioning && ./configure.sh $PREFIX && ENV=production ./install.sh )
}


main_entry()
{
  test -n "$1" || set -- all

  case "$1" in all|project|test|git )
      git --version >/dev/null ||
        stderr "Sorry, GIT is a pre-requisite" 1
    ;; esac

  case "$1" in pip|python )
      which pip >/dev/null || {
        cd /tmp/ && wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py; }
      pip install -r requirements.txt
    ;; esac

  case "$1" in all|build|test|sh-test|bats )
      test -x "$(which bats)" || { install_bats || return $?; }
    ;; esac

  case "$1" in dev|build|check|test|git-versioning )
      test -x "$(which git-versioning)" || {
        install_git_versioning || return $?; }
    ;; esac

  case "$1" in python|docopt )
      # Using import seems more robust than scanning pip list
      python -c 'import docopt' || { install_docopt || return $?; }
    ;; esac

  case "$1" in php|composer )
      test -x "$(which composer)" \
        || install_composer || return $?
    ;; esac

  case "$1" in dev|basher)
      test -x "$(which basher)" || {
        git clone https://github.com/basherpm/basher.git ~/.basher
        . bash/env.sh
        test -x "$(which basher)" && stderr "basher installed correctly" || stderr "missing basher" 1
      }
      basher update
    ;; esac

  stderr "OK. All pre-requisites for '$1' checked"
}

stderr "0: '$0'"
{
  test "$(basename "$0")" = "install-dependencies.sh"
} && {
  test -n "$1" -o "$1" != "-" || set -- all
  while test -n "$1"
  do
    main_entry "$1" || exit $?
    shift
  done
} || printf ""

# Id: user-conf/0.0.1-dev install-dependencies.sh
