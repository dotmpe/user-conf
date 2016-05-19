#!/bin/sh

set -e

mkdir -vp build

(

  ./script/user-conf/test.sh | tee ./build/test-results.tap

) || exit $?

