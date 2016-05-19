#!/bin/sh

set -e

uc_lib=script/user-conf
. "$uc_lib"/lib.sh

rm ./build/test-results.tap || printf ""

export $(echo $hostname | tr -s '-.' '__')_SKIP=1

mkdir -vp build

exec 3> ./build/test-results.tap
c_test "$@" 1>&3 || result=$?
exec 3<&-

echo "Test returned '$result'"

cat build/test-results.tap

exit $result

