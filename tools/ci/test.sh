#!/bin/sh

set -e

mkdir -vp build

(

  uc_lib=./script/user-conf
  . ./script/user-conf/test.sh

) | tee ./build/test-results.tap



