#!/bin/sh

base=uconf:update
test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"
. "$uc_lib"/lib.sh
c_update "$@"

