#!/bin/sh


tret=

{

  echo test.sh

  . ./script/user-conf/test.sh

  echo test.sh=$?

} | tee ./build/test-results.tap



