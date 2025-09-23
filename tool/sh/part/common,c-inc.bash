#!/usr/bin/env bash
: "${C_INC:=${HOME:?}/.l/c}"
# Add part dirs, for shared shell scripts
shopt -s nullglob
declare -a partdirs=( "${C_INC}"/tool/*/part )
shopt -s nullglob
declare partbase
for partbase in "${partdirs[@]}"
do OS-Path-Assert "${partbase:?}"
done
unset part{dirs,base}
#
#UserInc-Env-Init ()
#{
  declare -x C_INC
#}
#
