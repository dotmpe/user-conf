#!/bin/sh

set -e


mkdir -vp build
exec 3> ./build/test-results.tap
#./script/user-conf/test.sh || result=$?
uc_lib=script/user-conf ./script/user-conf/test.sh  1>&3 || result=$?
exec 3<&-

echo test.sh=$result

cat build/test-results.tap


exit $result

