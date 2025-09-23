#!/usr/bin/env bash
OS-Path-Assert "${UCONF:-/srv/uconf-local}"/script
_OS_Path_Assert "${U_C:?}"/script
_OS_Path_Assert "${U_S:?}"/src/sh/lib/

:pass () { return; }
:stat () { return ${1:?}; }
:ignore () { "$@" || true; }
:fun ()
{
  : param '<Function-name> <Function-body>'
  : input "${1:?Function name expected}"
  : input "${2:?Function body expected}"
  : "${1} () { ${*:2}; }"
  eval "$_"
}
:fun ':%' ':fun "$@"'

Sys-Argv-Firstseq ()
{
  : param '~ <Array> <Argv1...> -- <Argvn...>'
  : input "${1:?Array-name expected, $ENV_CTX:$FUNCNAME}"
  : input "${2:?Argument sequence expected, $ENV_CTX:$FUNCNAME}"
  local -n __sys_argv_firstseq_out=${1:?}
  shift
  local _arg
  for _arg
  do
    if [[ ${_arg} == '--' ]]
    then
      break
    fi
    __sys_argv_firstseq_out+=( "${_arg}" )
  done
  [[ $# -le $(( ${#__sys_argv_firstseq_out[*]} + 1 )) ]] ||
    return ${_E_continue:-195}
}
Sys-Read-Exec ()
{
  : about "Read command standard ouput (lines) into array"
  : extended "Reads onto end for existing array"
  : notes "To read words as items, see Sys-Read-Items"
  : param "<Array-name> <Cmd...>"
  : derive sys-exec-mapfile
  : input "${1:?Array-name expected, $ENV_CTX:$FUNCNAME}"
  : input "${2:?Command line expected, $ENV_CTX:$FUNCNAME}"
  local -n __Sys_Read_Exec_arr=${1}
  local outname=${1} offset
  [[ ${__Sys_Read_Exec_arr[*]:+set} ]] &&
  offset=${#__Sys_Read_Exec_arr[@]} || offset=0
  {
    if_ok "$("${@:2}")" || return ${_E_fail:-$?}
  } && {
    test -n "$_" || return ${_E_nz:-9}
  } &&
  <<< "$_" mapfile -O ${offset} ${mapfile_f:--t} ${outname}
}
declare -gA cwd
Local-Work-Dirs ()
{
  cwd[t460s]='~/{.conf,bin,.l/c,project/{user-conf,user-scripts}} /srv/annex-local/*/'
  cwd[t470p]='~/{.conf,bin,.l/c,htdocs,project/{user-conf,user-scripts{,-incubator}}} /srv/annex-local/*/ ~/{Desktop,Documents,Downloads,Pictures,Videos,Music}'
  cwd[fcys24]='~/{.conf,bin,.l/c,project/{user-conf,user-scripts{,-incubator}}} /srv/annex-local/*/'
}
expand-static ()
{
  : about "Perform expansion for shell string"
  : id sh-expand-static
  : input "${1:?Shell string}"
  if_ok "$(eval "echo $1")" &&
  <<< "${_}" read -a ${2:?}
}
read-nix ()
{
  : about "Print file data using grep or cat+grep"
  : description "File cat/grep helper that normally only prints non-empty, non-comment data"
  : param '(cat_f=) ~ File [Grep-Filter] ...'
  : id os-nix-file-data
  [[ $# -le 2 && "${1:-"-"}" = - || -e "${1-}" ]] || return 98
  [[ "${1-}" ]] || set -- "-" "${2-}"
  [[ "${2-}" ]] || set -- "$1" '^\s*(#.*|\s*)$'
  [[ -z "${cat_f-}" ]] && {
    grep -Ev "$2" "$1" || return $?
  } || {
    #shellcheck disable=2086
    cat $cat_f "$1" | grep -Ev "$2"
  }
}
declare -xf :pass :stat :ignore :fun :% Sys-Argv-Firstseq Sys-Read-Exec Local-Work-Dirs expand-static read-nix

