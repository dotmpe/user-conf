#!/bin/sh

set -e


mkdir -vp build
exec 3> ./build/test-results.tap
#./script/user-conf/test.sh || result=$?
./script/user-conf/test.sh  1>&3 || result=$?
exec 3<&-

echo test.sh=$result

exit $result

