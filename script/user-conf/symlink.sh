#!/bin/sh

base=uconf:symlink
test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"
. "$uc_lib"/lib.sh
{ c_symlink "$@" || exit $? ; } \
  2>&1 | ~/.conf/script/uc-colorize.sh

