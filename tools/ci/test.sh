#!/bin/sh

set -e

. ./test/helper.bash

current_test_env

check_skipped_envs $(current_test_env)

scriptname=$0

uc_lib=script/user-conf
. "$uc_lib"/lib.sh

rm ./build/test-results.tap || printf ""

log "Hostname: $(hostname)"
echo $(echo $hostname | tr -s 'a-z.-' 'A-Z__')_SKIP=1
export $(echo $hostname | tr -s 'a-z.-' 'A-Z__')_SKIP=1

mkdir -vp build

exec 3> ./build/test-results.tap
c_test "$@" 1>&3 || result=$?
exec 3<&-

log "Test returned '$result'"

cat build/test-results.tap

exit $result

