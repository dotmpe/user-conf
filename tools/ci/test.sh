#!/bin/sh

set -e

mkdir -vp build

(

  ./script/user-conf/test.sh || exit $?

) | tee ./build/test-results.tap

