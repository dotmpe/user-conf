#!/usr/bin/env bash

sudo=

test -n "$SRC_PREFIX" || {
SRC_PREFIX=$HOME
}

test -n "$PREFIX" || {
PREFIX=/usr/local
}

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

# Check for BATS shell test runner or install
test -x "$(which bats)" || {
  install_bats
  export PATH=$PATH:$PREFIX/bin
}

bats --version

# Id: git-versioning/0.0.27-test install-dependencies.sh
