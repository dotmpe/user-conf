#!/bin/sh

set -e


bats ./test/*-spec.bats || r=$?

echo r=$r

mkdir -vp build

(

  ./script/user-conf/test.sh | tee ./build/test-results.tap

) || exit $?

