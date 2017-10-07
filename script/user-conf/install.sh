#!/bin/sh

base=uconf:install
test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"
. "$uc_lib"/lib.sh
{ uc__install "$@" || exit $? ; } \
  2>&1 | ~/.conf/script/uc-colorize.sh

