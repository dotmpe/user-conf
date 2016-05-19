#!/bin/sh

set -e


( ./script/user-conf/test.sh || r=$? ) | tee ./build/test-results.tap
echo r=$r

mkdir -vp build

(

  ./script/user-conf/test.sh | tee ./build/test-results.tap

) || exit $?

