#!/bin/sh

set -e

exec 3> ./build/test-results.tap

uc_lib=./script/user-conf
./script/user-conf/test.sh  1>&3 || result=$?

exec 3<&-

echo test.sh=$result

exit $result

