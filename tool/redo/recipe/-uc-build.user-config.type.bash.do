#!/usr/bin/env bash

#us-env -r user-script uc-build &&
xredo_name=-uc-build.user-config.type.bash.do

case "${2:?}" in
( default.type.bash )
    # XXX: regenerate this file???
    redo-ifchange default.type.bash.do
  ;;

( * )
stderr echo ? $2
stderr echo do file $xredo_name
stderr echo 	1=$1
stderr echo 	2=$2
stderr echo 	3=$3
stderr declare -p REDO_{BASE,PWD,STARTDIR}
false
  ;;
esac
#
