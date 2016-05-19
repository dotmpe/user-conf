#!/bin/sh

set -e

tret=

{

  set -e

  echo test.sh

  uc_lib=./script/user-conf
  . ./script/user-conf/test.sh

  echo test.sh=$?

} | tee ./build/test-results.tap



