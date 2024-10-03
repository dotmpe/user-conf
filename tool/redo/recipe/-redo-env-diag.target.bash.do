#!/usr/bin/env bash
stderr declare -p REDO_{TARGET,BASE,PWD,STARTDIR}
for var in $(compgen -v -A arrayvar BASH_)
do
  stderr declare -p $var
done && unset var
#
