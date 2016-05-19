#!/bin/sh


tret=

{

  . ./script/user-conf/test.sh

  echo test.sh=$?

} | tee ./build/test-results.tap



