#!/bin/sh

set -e

mkdir -vp build

(

  uc_lib=./script/user-conf
  . ./script/user-conf/test.sh || r=$?
  echo r=$r rr=$rr

) | tee ./build/test-results.tap


exit 1


