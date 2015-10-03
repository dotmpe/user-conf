#!/bin/sh

base=uconf:test
test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"
. "$uc_lib"/lib.sh
export ${hostname}_SKIP=1
c_test

