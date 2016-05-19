#!/bin/sh

set -e

base=uconf:test
test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"
. "$uc_lib"/lib.sh
export $(echo $hostname | tr -s '-' '_')_SKIP=1
c_test "$@" || exit $?
exit 1
