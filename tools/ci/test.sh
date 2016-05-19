#!/bin/sh

set -e

mkdir -vp build

(

  . /script/user-conf/test.sh || r=$?
  echo r=$r rr=$rr

) | tee ./build/test-results.tap


exit 1


