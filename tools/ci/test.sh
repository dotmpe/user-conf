#!/bin/sh

set -e

hostnameid=

. ./test/helper.bash

current_test_env

echo hostname=$hostnameid
echo JENKINS_SERVER_AC_SKIP=$JENKINS_SERVER_AC_SKIP


#check_skipped_envs $(current_test_env)


uc_lib=script/user-conf
. "$uc_lib"/lib.sh

rm ./build/test-results.tap || printf ""

log "Hostname: $(hostname)"

mkdir -vp build

exec 3> ./build/test-results.tap
c_test "$@" 1>&3 || result=$?
exec 3<&-

log "Test returned '$result'"

cat build/test-results.tap

exit $result

