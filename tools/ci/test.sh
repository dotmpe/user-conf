#!/bin/sh

set -e


( ./script/user-conf/test.sh || r=$? ) | tee ./build/test-results.tap || rr=$?
echo r=$r rr=$rr

mkdir -vp build

(

  ./script/user-conf/test.sh | tee ./build/test-results.tap

) || exit $?

