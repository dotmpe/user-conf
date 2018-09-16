#!/bin/sh

set -e

base=uconf:init
test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"
. "$uc_lib"/lib.sh
{ uc__initialize "$@" || exit $? ; } \
  2>&1 | $UCONF/script/uc-colorize.sh
