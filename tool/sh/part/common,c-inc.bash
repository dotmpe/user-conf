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
: "${_E_GAE:=193}" # generic-argument-error/exception
: "${_E_MA:=194}" # missing-arguments
: "${_E_continue:=195}" # failed, can keep going (continue steps/batch)
: "${_E_next:=196}"  # partial success or next alternative
: "${_E_break:=197}" # success; last step, finish batch, ie. stop loop now and wrap-up
: "${_E_retry:=198}" # failed, but can or must reinvoke
: "${_E_limit:=199}" # generic value/param OOB error?
#
