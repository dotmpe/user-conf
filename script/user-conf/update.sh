#!/bin/sh

run_update()
{
  local base=uconf:update \
    failed=/tmp/$base.failed

  test ! -e $failed || rm $failed

  test -n "$uc_lib" || uc_lib="$(cd "$(dirname "$0")"; pwd)"
  . "$uc_lib"/lib.sh
  { uc__update "$@" || echo $? > $failed ; } \
    2>&1 | $UCONF/script/uc-colorize.sh

  test ! -e "$failed" || {
    ret=$(cat $failed)
    rm $failed
    return $ret
  }
}

run_update "$@"

