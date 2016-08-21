#!/bin/sh

base=uconf:install
test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"
. "$uc_lib"/lib.sh
{ c_install "$@" || exit $? ; } \
  2>&1 | ~/.conf/script/uc-colorize.sh

