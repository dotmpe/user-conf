# TODO: consolidate into ShellStarr node

[ -n "${BASH_VERSION-}" -o -n "${BASH-}" ] ||
    >&2 echo "-uconf-shell-core.sh is incompatible with ${SHELL-}"

[ "${_uconf_shell_core_-}" = "0" ] || {
  _uconf_shell_core_=1 # Loading core defs...

  _OS_Path_Add ()
  {
    : about "Simple PATH helper to append only new, unique instance"
    : param "<Directory> ..."
    : extended "Using this helps keeping PATH cleaner, but it doesnt behave"
    : extended "like path_append but returns false (1) if already found"
    : notes TODO "Really should write sys-wordv-add or something"
    : notes XXX "This does not export PATH"
    : notes : "Exactly the same implementation as shipped with Debian/Ubuntu"
    : src -uconf-shell-core.sh
    : input "${PATH?$ENV_CTX:$FUNCNAME: Path variable expected}"
    : input "${1:?$ENV_CTX:$FUNCNAME: Path value expected}"
    case ":${PATH}:" in
    ( *:"${1}":*) false
      ;;
    ( * )
        PATH="${PATH:+${PATH}:}${1}"
    esac
  }

  _OS_Path_Assert ()
  {
    _OS_Path_Add "$@" || test 1 -eq $? || return $_
    : src -uconf-shell-core.sh
  }

  _Sh_ByName_Add () # ~ <Variable-name> <Separator> <Value> ...
  {
    : src -uconf-shell-core.sh
    : "${1:?$ENV_CTX:$FUNCNAME: Variable name expected}"
    : "${2:?$ENV_CTX:$FUNCNAME: Separator expected for $1}"
    : "${3:?$ENV_CTX:$FUNCNAME: Append value expected for $1}"
    local -n _var=${1}
    _var=${_var-}${_var:+${2}}${3}
  }

  _Sh_Fun_Body ()
  {
    : param "~ <Ref-fun> ..."
    : src -uconf-shell-core.sh
    : input "${1:?$FUNCNAME: Function name expected}"
    :pass "$(typeset -f "${1}")" || return
    : "${_#* () }"
    : "${_:4:-2}"
    echo "$_"
  }

  _Sh_Fun_Eval ()
  {
    : about "Dynamic function from script-string"
    : param "<Function-name> <Function-body> ..."
    : src -uconf-shell-core.sh
    : id shell:fun:eval
    : input "${1:?$ENV_CTX:$FUNCNAME: Function name expected}"
    : input "${2:?$ENV_CTX:$FUNCNAME: $1: Function body expected}"
    : :# Format function and evaluate
    : "${1} () { ${*:2}; }"
    eval "$_"
  }

  _Sh_Fun_Exists ()
  {
    : src -uconf-shell-core.sh
    : input "${1:?${ENV_CTX}:$FUNCNAME: Symbol name expected}"
    >/dev/null typeset -F "${1}"
  }

  _Str_Glob_Match ()
  {
    : about "Inline glob match of String to Pattern"
    : param "<Pattern> <String> ..."
    : src -uconf-shell-core.sh
    : input "${1:?$ENV_CTX:$FUNCNAME: Pattern expected}"
    : input "${2:?$ENV_CTX:$FUNCNAME: $1: String value expected}"
    case "${2}" in ( ${1} ) ;; * ) false ;; esac
  }

  _Sys_Exec_Map ()
  {
    : about "Read command standard ouput (lines) into array"
    : param "~ <Array-name> <Cmd...>"
    : src -uconf-shell-core.sh
    : derive sys-exec-mapfile
    : input "${1:?${ENV_CTX}:$FUNCNAME: Array-name expected}"
    : input "${2:?${ENV_CTX}:$FUNCNAME: Command line expected}"
    local outname=${1} offset
    local -n __sys_exec_mapfile_arr=${outname}
    #: "${__sys_exec_mapfile_arr[*]?"$(sys_exc sys-execmap:array $1)"}"
    [[ ${__sys_exec_mapfile_arr[*]:+set} ]] &&
    offset=${#__sys_exec_mapfile_arr[@]} || offset=0
    if_ok "$("${@:2}")" &&
    test -n "$_" &&
    <<< "$_" mapfile -O ${offset} ${mapfile_f:--t} ${outname}
  }

  _uconf_shell_core_=2 #
}

# Make sure logging DSL is ready
# uconf-shell-log always loads completely on source, but does
# load-once-then-refresh handling too
[[ ${_uconf_shell_log_} = 0 ]] ||
. /srv/conf-local/tool/uconf/part/-uconf-shell-log.sh

[ "${_uconf_shell_core_-}" = "0" ] || {
  _uconf_shell_core_=3 #

  _Sh_Fun_Exists uc_env || {
    : "${UC_ENV_PART:=${U_C:-/src/local/user-conf+current}/tool/uc/part/-env,fun,uc.sh}"
    . "${UC_ENV_PART}"
  }

  :pass () { return; }
  uc_env +if-init

  uc-env::uconf-shell-core-dsl () {
    : type uc:comp:dsl
    : src -uconf-shell-core.sh
    : super uc-env-core
    # UConf Shell Core DSL
    uc_env +d dx :body '_Sh_Fun_Body "${@}"'
    uc_env +d dx :fnMatch '_Str_Glob_Match "${2}" "${1}"'
    uc_env +d dx :isFun '_Sh_Fun_Exists "${@}"'
    uc_env +d dx :mapExec '_Sys_Exec_Map "${@}"'
    uc_env +d dx :mkFun '_Sh_Fun_Eval "${@}"'
    uc_env +d dx :pass 'return'
  }

  uc-env::shell-strvar-dsl () {
    : type uc:comp:dsl
    : super uc-env-core
    : src -uconf-shell-core.sh
    # Shell Stringvar DSL
    uc_env +d dx :concatByName '_Sh_ByName_Add "${1}" "" "${2}"'
    uc_env +d dx :n+ ':concatByName "${@}"'
    uc_env +d dx :concatWordByName '_Sh_ByName_Add "${1}" " " "${2}"'
    uc_env +d dx :w+ ':concatWordByName "${@}"'
    uc_env +d dx :concatColonByName '_Sh_ByName_Add "${1}" : "${2}"'
    uc_env +d dx :+ ':concatColonByName "${@}"'
    uc_env +d dx _+ ':strConcatWordByName "${@}"'
    uc_env +d dx .+ '_Sh_ByName_Add "${1}" . "${2}"'
    uc_env +d dx _+_ '_Sh_ByName_Add "${@}"'
  }

  # Backward compatibility: Deprecated/proof of concept set
  uc-env::bwc-dx () {
    : type uc:comp:dsl
    : super uc-env-core
    : src -uconf-shell-core.sh
    # TODO: cleanup local namespace
    uc_env +d dx add_path '_OS_Path_Add "${@}" || true'
    uc_env +d dx fnmatch '_Str_Glob_Match "${2}" "${1}"'
    uc_env +d dx sh_fun '_Sh_Fun_Exists "${@}"'
    uc_env +d dx sh_vadd '_Sh_ByName_Add "${@}"'
    uc_env +d dx sh_funbody '_Sh_Fun_Body "${@}"'
    uc_env +d dx sh_mapfile '_Sys_Exec_Map "${@}"'
    uc_env +d dx if_ok 'return'
    uc_env +d dx stderr '>&2 "${@}"'
  }

  uc_env @contexts uconf-shell-core-dsl shell-strvar-dsl bwc-dx

  # Standard OS
  uc_env +d dx append_path ': param "<DIR>"
: about "PATH helper"
_OS_Path_Add "${@}" || true'

  # TODO: perform stuff like this based on Mode/Session/Role settings
  # TODO: revise all logging
  : "${UC_SYSLOG_LEVEL:=4}"
  : "${uc_stat:=return}"

  # XXX: removed ENV_CTX, think about managing other ENV
  uc_env @exports \
    ENV_{BASE,LIB,SRC} \
    UC_SYSLOG_LEVEL uc_stat \
    UC_SHELL_DEBUG UC_DEBUG DEBUG VERBOSE QUIET v
  #export UC_SH_ALIASES=false
  #export QUIET=false
  #export VERBOSE=true
  #export UC_SHELL_DEBUG=true
  #export UC_DEBUG=true
  #export DBUS_DEBUG=false
  #export DEBUG=true

  set -- uc_env \
    _OS_Path_Add \
    _OS_Path_Assert \
    _Sh_ByName_Add \
    _Sh_Fun_Body \
    _Sh_Fun_Eval \
    _Sh_Fun_Exists \
    _Str_Glob_Match \
    _Sys_Exec_Map

  uc_env @functions "$@"
  uc_env @exports "$@"
  uc_env :export

  _uconf_shell_core_=0 # Finish
}

# XXX: Found this log config appropiate here for desktop environments
# Specifically, some login managers will present dialogs after logging in
# with standard error, if produced by any of the profile or rc files.
case "${0##*/}" in
  ( *-session | Xsession ) export QUIET=true ;;
esac

# Id: uc:shell:core $PREFIX/share/uc/etc/profile                    ex:ft=bash:
