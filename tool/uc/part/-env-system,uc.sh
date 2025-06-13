[[ ${BASH+set} ]] || {
  _CRIT "-env-system,uc.sh part is incompatible with shell ${SHELL:-(unspecified)}"
  return
}

#ENV_SRC=${ENV_SRC:-$0[$$]:}${ENV_SRC:+ }/etc/profile.d/us-system.sh
#ENV_CTX=${ENV_CTX:-$0[$$]:}${ENV_CTX:+ }us-system

case " ${ENV_BASE?} " in ( *" us-system "* )
  # Login sub-shells and interactive sub-shells will inevitably loop
  _ALERT "-env-system,uc.sh: group is already loaded"
  return
;; esac

uc_env @part G us-system /etc/profile.d/us-system.sh
# ENV_SRC=${ENV_SRC:-$0[$$]:}${ENV_SRC:+ }/etc/profile.d/us-system.sh

# Inline: uc-sh-util

uc_env @part G uc-sh-util

_Sh_Als_Exp ()
{
  : about "Expand alias to full script"
  : extended "This will only work if aliases are completely loaded"
  : src us-system.sh
  : input "${1:?$ENV_CTX:$FUNCNAME: Alias name expected}"
  local fun=__fun_tmp_${RANDOM:?}
  eval "$fun ()
{
  ${1}
}" &&
  _Sh_Fun_Body "$fun" &&
  unset -f "$fun"
}
uc_env_types["_Sh_Als_Exp"]=f

_Sh_Caller ()
{
  : param '~ [<Frame=0>]'
  : src us-system.sh
  : "$(( ${1:-0} + 1 ))"
  :pass "$(caller $_)" || return
  : "${_#* }"
  : "${_% *}"
  echo "$_"
}
uc_env_types["_Sh_Caller"]=f

_Sh_Callers ()
{
  : about "List function call stack"
  : param '~ [<Start-frame=0>]'
  : src us-system.sh
  local i
  for (( i=${1-0}; 1; i++ ))
  do caller $i || break
  done
}
uc_env_types["_Sh_Callers"]=f

uc_env_exports+=( _Sh_{Als_Exp,Caller{,s}} )


# Inline: uc-core

uc_env @part G uc-core

# Verbose non-zero for script-related status, default to E:script.
sh_abort () # ~ <Key> <Message> [<Status>] [<Vars>] [<Types>]
{
  : "${1:?$ENV_CTX:$FUNCNAME: Key expected}"
  : "${2:?$ENV_CTX:$FUNCNAME: Id expected}"
  : ${3:-${_E_script:-2}}
  sh_vstat ${_} "Abort: ${1}" "${2}" "${@:4}"
  ${uc_stat:-exit} $?
}
uc_env_types["sh_abort"]=f

sh_exc () # ~ <Key> <Short> <...> # Shell abort message helper
{
  sh_vstat "" "Variable or argument error ${1}" "${@:2}"
}
uc_env_types["sh_exc"]=f
# Copy: compo:inc:sh-exc

# Verbose non-zero for lesser issue than script, ie (user or meta) data.
# Default to E:user.
sh_stop () # ~ <Key> <Message> [<Status>] [<Vars>] [<Types>]
{
  : "${1:?$ENV_CTX:$FUNCNAME: Key expected}"
  : "${2:?$ENV_CTX:$FUNCNAME: Id expected}"
  : ${3:-${_E_user:-3}}
  sh_vstat ${_} "Stop: ${1}" "${2}" "${@:4}"
  ${uc_stat:-exit} $?
}
uc_env_types["sh_stop"]=f

sh_vstat () # ~ <Status> <Id> <Short> [<Context ...>
{
  : "${2:?$ENV_CTX:$FUNCNAME: Id expected}"

  [[
    ${QUIET:-false} != true &&
    ${SILENT:-false} != true
  ]] ||
    echo "$0[$$] ${2}: ${3-E$1}" >&2

  [[ ! ${1:+set} ]] || return ${1}
}
uc_env_types["sh_vstat"]=f
# Copy: compo:inc:sh-vstat

uc_env_exports+=(
  sh_{abort,exc,stop,vstat}
)


# Inline: uc-base

uc_env @part G uc-base

incr () # ~ <Variable-name> [<Increment-value>] ...
{
  : "${1:?$(sh_exc us-system:$FUNCNAME "Variable name expected")}"
  local -n _intv=${!_-}
  _intv=$(( $_intv + ${2:-1} ))
}
uc_env_types["incr"]=f
# Group: compo:inc:sh-userutil
# Copy: compo:inc:incr

# Given name is symbol for array variable (associative)
sh_aarr () # ~ <Varname> ...
{
  : "${1:?$(sh_exc us-system:$FUNCNAME "Array variable name expected")}"
  sh_vfl "A" "${1}"
}
uc_env_types["aar"]=f
# Group: compo:inc:sh-meta
# Copy: compo:inc:sh-aarr

# Given name is symbol for array variable (either indexed or associative)
sh_arr () # ~ <Varname> ...
{
  : "${1:?$(sh_exc us-system:$FUNCNAME "Array variable name expected")}"
  sh_vfl "aA" "${1}"
}
uc_env_types["sh_arr"]=f
# Group: compo:inc:sh-meta
# Copy: compo:inc:sh-arr

sh_iarr () # ~ <Name> ... # Test for index-array symbol
{
  : "${1:?$(sh_exc us-system:$FUNCNAME "Array variable name expected")}"
  sh_vfl "a" "${1}"
}
uc_env_types["sh_iarr"]=f
# Group: compo:inc:sh-meta
# Copy: compo:inc:sh-iarr

sh_typeset () # ~ <Name> ...
{
  : "${1:?$(sh_exc us-system:$FUNCNAME "Function name expected")}"
  declare -f "${1}" 2>/dev/null
}
uc_env_types["sh_typeset"]=f
# Group: compo:inc:sh-type
# Copy: compo:inc:sh-typeset

sh_var () # ~ <Name> ... # Test for variable symbol
{
  : "${1:?$(sh_exc us-system:$FUNCNAME "Variable name expected")}"
  declare -p "${1}" > /dev/null 2>&1
}
uc_env_types["sh_var"]=f
# Group: compo:inc:sh-type
# Copy: compo:inc:sh-var

std_noerr () # ~ <Cmd...> # Void secondary output
{
  : "${@:?$(sh_exc us-system:$FUNCNAME "Command expected")}"
  "$@" 2>/dev/null
}
uc_env_types["std_noerr"]=f
# Group: compo:inc:std-util
# Copy: compo:inc:std-noerr

std_noout () # ~ <Cmd...> # Void primary output
{
  : "${@:?$(sh_exc us-system:$FUNCNAME "Command expected")}"
  "$@" >/dev/null
}
uc_env_types["std_noout"]=f
# Group: compo:inc:std-util
# Copy: compo:inc:std-noout

std_quiet () # ~ <Cmd...> # Void regular output (std{out,err})
{
  : "${@:?$(sh_exc us-system:$FUNCNAME "Command expected")}"
  "$@" >/dev/null 2>&1
}
uc_env_types["std_quiet"]=f
# Group: compo:inc:std-util
# Copy: compo:inc:std-quiet

stderr () # ~ <Cmd...> # Redirect output to second stream
{
  : "${@:?$(sh_exc us-system:$FUNCNAME "Command expected")}"
  "$@" >&2
}
uc_env_types["stderr"]=f
# Group: compo:inc:std-util
# Copy: compo:inc:stderr

str_globmatch () # ~ <String> <Glob-pattern>
{
  : "${1:?$(sh_exc us-system:$FUNCNAME "String value expected")}"
  : "${2:?$(sh_exc us-system:$FUNCNAME "Glob pattern expected")}"
  case "${1}" in ( ${2} ) ;;
  ( * ) false
  esac
}
uc_env_types["str_globmatch"]=f
# Group: compo:inc:str
# Copy: compo:inc:str-globmatch

# string-util function with optional case conversion.
str_vword () # ~ <Variable> [<String>] # Transform/default word string value
{
  : "${1:?$(sh_exc us-system:$FUNCNAME "Variable name expected")}"
  declare -n _var=${1}
  : "${2-$_var}"
  _var="${_//[^A-Za-z0-9_]/_}"
  [[ "${upper:-false}" != true ]] && {
    [[ "${lower:-false}" != true ]] || _var="${_var,,}"
  } || _var="${_var^^}"
}
uc_env_types["str_vword"]=f

# Restrict used characters to 'word' class (alpha numeric and underscore);
# string-util function with optional case conversion.
str_word () # ~ <String> # Transform string to word
{
  : "${1:?$(sh_exc us-system:$FUNCNAME "String value expected")}"
  local out="${_//[^A-Za-z0-9_]/_}"
  [[ "${upper:-false}" != true ]] && {
    [[ "${lower:-false}" != true ]] &&
      echo "$out" ||
      echo "${out,,}"
  } || echo "${out^^}"
}
uc_env_types["str_word"]=f

str_wordmatch () # ~ <Word> <Strings...> # Non-zero unless word appears
{
  : "${1:?$(sh_exc us-system:$FUNCNAME "Word value expected")}"
  : "${*:2}"
  : "${_:?$(sh_exc us-system:$FUNCNAME "Space separated values expected")}"
  case " ${_} " in
  ( *" ${1} "*) ;;
  ( * ) false
  esac
}
uc_env_types["str_wordmatch"]=f

uc_env_exports+=(
  if_ok
  incr
  sh_{fun,{a,i,}arr,typeset,var}
  std{_{no{err,out},quiet},err}
  str_{{glob,word}match,{v,}word}
)

# Inline: sys-log

uc_env @part G sys-log

[[ ! -s /etc/uc/log ]] || {

  # XXX: pre-export any other vrs
  : "$(grep -v '^\(#.*\|[ $'\t\n\r']*\)$' /etc/uc/log)"
  test -z "$_" || {
    : "$(<<< "$_" sed 's/^\([A-Za-z_][A-Z0-9a-z_]*\)=.*$/\1/')"
    <<< "$_" mapfile -t -O ${#uc_env_exports[*]} uc_env_exports
  }
}

sys_log_env ()
{
  [[ ! -s /etc/uc/log ]] || {
    : "$(grep -v '^\(#.*\|[ $'\t\n\r']*\)$' /etc/uc/log)"
    test -z "$_" || {
      eval "$_" ||
      _CRIT "UC log settings failed: E$? /etc/uc/log"
    }
  }
  : "${LOG:=/etc/profile.d/uc-profile.sh}"
}
uc_env_types["sys_log_env"]=f
uc_env_exports+=( sys_log_env )

#uc_env @locals BASH_UC_{SCRIPTNAME,SCRIPTTAG}
uc_env @exports LOG UC_LOG_BASE

_. "uc_env_hooks[\"start\"]" ' ' sys_log_env

# Inline: os-release

uc_env @part G os-release

[[ ! -s /etc/os-release ]] || {

  # XXX: It's not very nice, but simple and effective.
  # afaic os-release isnt shell-formatted (but happens to be so??)
  # It could be I should be using lsb-release...
  : "$(sed 's/^\([^=]*\)=.*$/OS_\1/' /etc/os-release)"
  test -z "$_" || {
    <<< "$_" mapfile -t -O ${#uc_env_exports[*]} uc_env_exports
    : "$(sed 's/^/OS_/g' /etc/os-release)"
    eval "$_" ||
      _CRIT "OS release failed: E$? /etc/os-release"
  }
  # Typical values for ubuntu and debian based
  # are OS_{NAME,ID{,_LIKE},VERSION{,_{CODENAME,ID}}} and others
  # Scripts cannot really expect any of these to be set though.
}

# Inline: os-host

uc_env @part G os-host

OS_HOST=$(hostname --long)
: "$(hostname --short)"
OS_HOSTNAME=${_,,}
OS_UNAME=$(uname -s)

uc_env @by-name HOST OS_HOSTNAME

SYS_MACH=$(uname -m)                # Machine name
SYS_ARCH=$(uname -i)                # Hardware platform (non-portable)
SYS_PROC=$(uname -p)                # Processor (non-portable)

uc_env_exports+=(
  HOST
  OS_{HOST{,NAME},UNAME}
  SYS_{MACH,ARCH,PROC}
)

# Inline: os-path

uc_env @part G os-path

uc_env +d dx os_add '_OS_Path_Add "$@" || true'
uc_env +d dx os_path_add '_OS_Path_Add "$@"'

[[ ${OS_OVERRIDE:-false} != true ]] || {
  os_prefix ()
  {
    case ":$PATH:" in
    ( *:"${1:?}":*) false ;;
    ( * ) PATH="${1:?}${PATH:+:$PATH}"
    esac
  }
  os_path_prefix ()
  {
    local -n _PATH=${1:?Variable name expected}
    case ":$_PATH:" in
    ( *:"${1:?}":*) false ;;
    ( * ) _PATH="${1:?}${_PATH:+:$_PATH}"
    esac
  }
  uc_env_exports+=( os_{,path_}prefix )
}

# Inline: uc-host

uc_env @part G uc-host

[[ ! -s /etc/uc/host ]] || {

  # XXX: It's not very nice, but simple and effective for now
  : "$(grep -v '^\(#.*\|[ $'\t\n\r']*\)$' /etc/uc/host)"
  test -z "$_" || {
    eval "$_" &&
    : "$(<<< "$_" sed 's/^\([A-Za-z_][A-Z0-9a-z_]*\)=.*$/\1/')" &&
    <<< "$_" mapfile -t -O ${#uc_env_exports[*]} uc_env_exports ||
      _CRIT "UC host settings failed: E$? /etc/uc/host"
  }
}

_INFO "Loaded -env-system,uc"
# Id: -env-system,uc /etc/profile.d/us-system.sh
