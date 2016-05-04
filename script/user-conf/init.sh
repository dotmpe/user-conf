#!/bin/sh

set -e

base=uconf:init
test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"
. "$uc_lib"/lib.sh
c_initialize "$@" || exit $?

