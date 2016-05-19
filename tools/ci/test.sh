#!/bin/sh


tret=

{

  ./script/user-conf/test.sh || r=$tret
  echo tret=$tret
  test -z "$tret" || exit $tret

} | tee ./build/test-results.tap



