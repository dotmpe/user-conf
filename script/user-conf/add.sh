#!/bin/sh

base=uconf:add
test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"
. "$uc_lib"/lib.sh
{ c_add "$@" || exit $? ; } \
  2>&1 | ~/.conf/script/uc-colorize.sh

