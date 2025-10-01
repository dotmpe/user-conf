#shellcheck disable=SC2120 # Ignore, args_uc__argc is doing some checks

# Helper to source libs only once
uc_profile_load_lib ()
{
  [[ ${BASH_UC_SCRIPTTAG+set} ]] || {
    : "$(</proc/uptime)"
    : "$$:${_% *}"
    : "${BASH_UC_SCRIPTTAG:="$0[$_]:uc-profile"}"
  }

  test "0" = "${UC_PROFILE_SRC_LIB-}" || {
    [ -z "$_" ] || _CRIT "Possible recursion at uc-profile-load-lib" || return
    uc_profile_source_lib || return
  }
}

# Include first existing tool/sh/profile.sh
uc_profile_boot_parts ()
{
  for bd in ${UC_BOOT_PATH:-${UCONF:?} ${U_C:?}}
  do
    test -s "$bd/tool/sh/profile.sh" || continue
    #shellcheck source=tool/sh/profile.sh
    . "$bd/tool/sh/profile.sh"
    break
  done
  unset bd
}


uc_cmd ()
{
  [[ $# -eq 1 ]] || return ${_E_GAE:-193}
  #args_uc__argc :uc-cmd $# eq 1 || return
  test -x "$(command -v "$1")"
}

uc_diag ()
{
  : "${UC_TAB:?}"
}

# Use UC_DEBUG to get more logs about what uc-profile is doing, see also
# US_DEBUG and DEBUG. XXX: SHDEBUG
uc_debug () # ~ [ <Cmd...> ] # Test for or execute command if env debug is on
{
  [[ 0 -ne $# ]] && {
    uc_debug || return ${_E_next:?}
    "$@"
    return
  } ||
    "${UC_DEBUG:-${DEBUG:-false}}"
}

# An exception helper, e.g. for inside ${var?...} expressions
uc_exc () # ~ <Head>: <Label> # Format exception-id and message
{
  local \
    uc_sys_exc_id=${1:-uc:exc:$0:${*// /:}} \
    uc_sys_exc_msg=${2-Expected}
  ! uc_debug &&
  echo "$uc_sys_exc_id${uc_sys_exc_msg:+: $uc_sys_exc_msg}" ||
    "${uc_sys_on_exc:-uc_sys_source_trace}" "$uc_sys_exc_id" "$uc_sys_exc_msg" 3 "${@:3}"
}
# Derive: sys-exc

# TODO: replace these with sh_env either from shell-uc.lib or shell.lib
uc_fun () # ~ <Function-name>
{
  # DEV: args_uc__argc :uc-func $# eq 1 || return
  #test "$(type -t "$1")" = "function"
  # Fasted for Bash
  declare -F "${1:?}" >/dev/null 2>&1
}
# sh_fun () { declare -F "${1:?}" > /dev/null; }

# Same as uc-source but also take snapshot of env vars name-list
uc_profile_import () # ~ [Source-Path]
{
  uc_source "${1:?"$(uc_exc uc:profile-import)"}"
  return

  # XXX: see new uc-env for preemptive tracking
  : "${1//\//-}" &&
  #if_ok "$(uc_profile_mkid <<< "${_}" )" &&
  if_ok "$(echo "$_" | uc_profile_mkid )" &&
  uc_profile__record_env__keys "${_:?}" ||
    "${uc_log:-${LOG?}}" error ":import" "Loading shell file" "E$?:$1" $? ||
    return

  # TODO: record ENV-SRC snapshot as well.
  ! uc_debug ||
    "${uc_log:-${LOG?}}" warn ":import" "New env loaded, keys stored" "$1"
}

#
uc_profile_mkid () # ~
{
  [[ $# -eq 0 ]] || return ${_E_GAE:-193}
  #args_uc__argc :env-keys $# || return
  tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]'
}

uc_profile_part () # ~ <Name>
{
  : "${1:?uc-profile-part:name}"
  local profile_d
  for profile_d in ${UC_PROFILE_D//[:]/ }
  do
    test -e "$profile_d/$1.sh" || continue
    echo "$profile_d/$1.sh"
    break
  done
}

uc_profile_partnames () # ~ <Namespec>
{
  : "${1:?uc-profile-part:namespec}"
  uc_profile_parts "$@" | while read -r path
  do
    : "${path##*/}"
    echo "${_%.sh}"
  done
}

uc_profile_parts () # ~ <Namespec>
{
  : "${1:?uc-profile-part:namespec}"
  local profile_d
  for profile_d in ${UC_PROFILE_D//[:]/ }
  do
    ( cd "$profile_d" && compgen -G "$1.sh" )
  done
}

#shellcheck disable=1091 # Cannot add source directives here
# The actual source part for uc-profile-load-lib
uc_profile_source_lib () # ~
{
  [ -z "${UC_PROFILE_SRC_LIB-}" ] || {
    _CRIT "Possible recursion at uc-profile-source-lib" || return
  }
  UC_PROFILE_SRC_LIB=1

  >/dev/null 2>&1 declare -F lib_require || {
    : "${U_C:-/src/local/user-conf+current}"
    : "${UC_LIB_PATH:=$_/script}"
    . "${UC_LIB_PATH:?}/lib-uc.lib.sh" &&
    lib_uc_lib__load &&
    lib_uc_lib__init || return
  }

  #_NOTICE "Ready to source libs and init"
  # FIXME: build proper cached profile...
  #test -n "${uc_lib_profile:-}" || . "${UCONF:?}/etc/profile.d/bash_fun.sh"

  # FIXME: lib-require in lib-init
  lib_require shell-uc str-uc syslog-uc &&
  #_NOTICE "Initializing" &&
  lib_init &&
  #_NOTICE "Done"
  true

  UC_PROFILE_SRC_LIB=$?

  return $UC_PROFILE_SRC_LIB
}

# Set Id for shell session. This should be run first thing,
# when next to no profile whatsoever has been loaded.
uc_profile_init () # ~
{
  INIT_LOG=${LOG:?}

  uc_profile_load_lib || return

  # XXX: uc_ctx HOST PWD 0 - USER

  [[ $# -eq 1 ]] || return ${_E_GAE:-193}
  #args_uc__argc :init $# eq 1 || return

  set -- $(printf -- '%s:' $(hostname -s) $USER $(basename -- "$SHELL") $$ "$1")
  export UC_SH_ID="${1:0:-1}"

  # Comply with dynamic init of non-interactive shell, but be more cautious
  [ -z "${PS1-}" ] && {
    # Don't try to exit in the middle of a script
    UC_LOG_EXITS=-1
  } || {

    # Some RC stuff
    test -z "${BASH}" || {
      set -h # Remember the location of commands as they are looked up. (same as hashall)
      set -E # If set, the ERR trap is inherited by shell functions.
      set -T
      #set -e
      set -u # Treat unset variables as an error when substituting. (same as nounset)
      set -o pipefail #
      shopt -s extdebug
    }
  }

  uc_log_init && {
    "${uc_log:-${LOG?}}" "info" ":init" "U-c profile init has started dynamic shell setup" "-:$-"
    : "${LOG:=uc_log}"

  } || {
    # Something's already wrong, see if log works or fail Uc-profile init completely.
    LOG="${UC_PROFILE_SELF}"
    $LOG "warn" ":init" "U-c profile init has failed dynamic setup" "-:$-" || {
      export UC_FAIL=1
    }
  }

  test "0" = "${UC_FAIL:-0}" || return $_
  unset INIT_LOG
  UC_PROFILE_INIT=1
  "${uc_log:-${LOG?}}" "info" ":init" "U-c profile init done, proceeding"
}

# Finalize init for shell session
uc_profile_start () # ~
{
  #args_uc__argc :start $# || return
  [[ $# -eq 0 ]] || return ${_E_GAE:-193}

  # Be nice and switch logger back to exec script
  export LOG="${UC_PROFILE_SELF}"

  local sh
  test -n "${BASH-}" && sh=BASH || sh=SH
  trap uc_profile_cleanup_$sh exit

  # Turn off NO-UNDEFINED again as most autocompletion scripts don't like it
  flags=$-
  set +$( for optflag in $(echo $flags | sed 's/./& /g')
    do case "$optflag" in ( e | u | E | T ) printf $optflag ;; esac
    done )
  unset flags

  typeset ctx
  ctx="$0($-)[$$]"
  ctx="${HOSTTYPE:?}${HOSTTYPE:+:}$ctx"
  ctx="${HOST:?}${HOST:+:}$ctx"

  ctx="${UC_PROFILE_TP:-}${UC_PROFILE_TP:+:}$ctx"
  ctx="${XDG_SESSION_TYPE:-}${XDG_SESSION_TYPE:+:}$ctx"
  ctx="${SSH_TTY:+ssh:}$ctx"

  ctx="${ENV:-}${ENV:+::}$ctx"

  typeset bootsec=$(( $(date +%s) - uc_profile_start ))
  [[ $bootsec -le 2 ]] && : "" || : " after ${bootsec}s"
  "${uc_log:-${LOG?}}" "notice" ":start" "Session ready$_" "$ctx"
}

# Add parts (scripts) to shell session
uc_profile_load () # ~ NAME [TAG]
{
  #args_uc__argc :load $# gt || return
  [[ $# -gt 0 ]] || return ${_E_GAE:-193}
  ! uc_debug ||
    "${uc_log:-${LOG?}}" debug :load "Start loading part" "$#:$*"

  local uc_profile_part_exists=1 uc_profile_partname="$1" uc_profile_part_envvar uc_profile_part_ret
  globmatch "-*" "$1" && {
    uc_profile_part_exists=0; uc_profile_partname="${1:1}"
  }
  shift
  : "${uc_profile_partname^^}"
  uc_profile_part_envvar=UC_PROFILE_D_${_//[^A-Z0-9_]/_}

  # XXX: Skip if already loaded
  #test -z "$(eval "echo \"\${$uc_profile_part_envvar-}\"")" || return 0
  test -z "${!uc_profile_part_envvar:-}" || return 0

  # During loading UC_PROFILE_D_<name>=1, and at the end it is set to the source return status.
  # However the script itself....
  eval $uc_profile_part_envvar=-1

  # During source of the env file, `uc_profile_load{,_path,_tag}` can be referred to.

  local uc_profile_load="$1" uc_profile_tag="${2:-}"

  local uc_profile_load_path=$(uc_profile_part "$uc_profile_partname")

  # Bail if no such <name> profile exists
  [ -n "$uc_profile_load_path" ] &&
  [ -e "$uc_profile_load_path" ] || {
    # error unless '*<name>' was specified
    test $uc_profile_part_exists -eq 0 && return 255 # ie. -1
    #>&2 echo "No such part found $uc_profile_partname"
    "${uc_log:-${LOG?}}" "error" ":load" "Error: no uc-source" "name:$uc_profile_partname;*:$*"
    return 6
  }

  ! uc_debug ||
    "${uc_log:-${LOG?}}" debug ":load" "Loading part" "$*:$uc_profile_partname"
  uc_source "$uc_profile_load_path"
  uc_profile_part_ret=$?
  "${uc_log:-${LOG?}}" debug ":load" "Loaded part" "$*:$uc_profile_partname:E$uc_profile_part_ret"

  local _stat="${!uc_profile_part_envvar-}"

  # File exists, so we have a status either way
  test "${_stat}" != "-1" || unset $uc_profile_part_envvar

  # If non-zero and not pending, set UC_PROFILE_D_<name> to status.
  # Otherwise return pending directly and unset UC_PROFILE_D_<name>
  test $uc_profile_part_ret -eq 0 || {
    test $uc_profile_part_ret -eq $E_UC_PENDING && {
      return $E_UC_PENDING
    }
  }

  eval $uc_profile_part_envvar=$uc_profile_part_ret
  return $uc_profile_part_ret
}

# End shell session
uc_profile_cleanup ()
{
  shopt -s nullglob
  set -- "$SD_SHELL_DIR/$UC_SH_ID"*.sh
  test $# -eq 0 || rm "$@"
  exit ${rs-}
}

# Exit trap handlers specific to Shell version
uc_profile_cleanup_SH ()
{
  local rs=${?:-0}
  test $rs -eq 0 || {
    uc_signal_exit $rs && {
      "${uc_log:-${LOG?}}" "warn" ":cleanup" "Some command exited after signal $signal_name ($exit_signal) [$rs]"
    } || "${uc_log:-${LOG?}}" "warn" ":cleanup" "Some command exited with code [$rs]"
  }
  uc_profile_cleanup
}

uc_profile_cleanup_BASH ()
{
  local lc="$BASH_COMMAND" rs=${?:-0}
  test $rs -eq 0 || {
    uc_signal_exit $rs && {
      "${uc_log:-${LOG?}}" "warn" ":cleanup" "Command [$lc] exited after signal $signal_name ($exit_signal) [$rs]"
    } || "${uc_log:-${LOG?}}" "warn" ":cleanup" "Command [$lc] exited with code [$rs]"
  }
  uc_profile_cleanup
}

# Record env keys only; assuming thats safe, no literal dump b/c of secrets
uc_profile__record_env__keys ()
{
  [ $# -eq 1 ] || return ${_E_GAE:-193}
  #args_uc__argc_n :record-env:keys $# eq 1 || return
  [ ! -e "$SD_SHELL_DIR/$UC_SH_ID:$1.sh" ] || {
    "${uc_log:-${LOG?}}" "error" ":record-env:keys" "Keys already exist" "$1"
    return 1
  }
  env_keys > "$SD_SHELL_DIR/$UC_SH_ID:$1.sh"
}

uc_profile__record_env__ls ()
{
  [[ $# -eq 0 ]] || return ${_E_GAE:-193}
  #args_uc__argc_n :record-env-ls $# || return
  for name in "$SD_SHELL_DIR/$UC_SH_ID"*
  do
    echo "$(ls -la "$name") $( count_lines "$name") keys"
  done
}

# Besides init/start/end this is the mayor step of UC-profile, performed
# one or several times during shell init. For this reason this should never
# return an error.
uc_profile_boot () # TAB [types...]
{
  : "${uc_profile_start:=$(date +%s)}"
  test -n "${1-}" || set -- "${UC_TAB:?}" "${@:2}"
  test -s "${1-}" || {
    "${uc_log:-${LOG?}}" "crit" ":boot" "Missing or empty profile table" "${1-}"
    return
  }

  test $# -gt 0 -a -e "${1-}" || return 64
  local tab="$1"; shift 1

  test $# -gt 0 && UC_PROFILE_TP="$*" || set -- ${UC_PROFILE_TP:?}

  local c="${UC_RT_DIR:?}/user-$(id -u)-profile.tab"
  test ! -e "$c" -o "$c" -ot "$tab" && {
    grep -v -e '^ *#' -e '^ *$' "$tab" >"$c"
  }

  test ! -e "$c" -o "$c" -ot "$tab" && {
    grep -v -e '^ *#' -e '^ *$' "$tab" >"$c"
  }

  "${uc_log:-${LOG?}}" "info" ":boot" "Start sourcing profile.tab parts" "$*:wcl=$(wc -l "$c")"

  local name{,s,spec} type
  while read -r namespec type
  do
    test -n "$type" -a $# -gt 0 && {
      # Skip entry unless '$*' matches any type for entry
      local tp m=0
      for tp in "$@"; do globmatch "* $tp *" " $type " && m=1 || continue; done

      test $m -eq 1 || {
        ! uc_debug ||
          "${uc_log:-${LOG?}}" warn ":boot<>$namespec" "Skipped profile.tab entry" "$type not in $*"
        continue
      }
    }

    # test for globs, and expand those first
    if globmatch "*[\*\?]*" "$namespec"
    then
      # Use Bash compgen to expand glob
      # Also '-' prefix must be handled here
      globmatch "-*" "$namespec" &&
        require=false namespec=${namespec:1} || require=true

      :pass "$(uc_profile_partnames "$namespec")" &&
      mapfile -t names <<< "${_}" || names=()

      [ "${require}" = false ] || [ ${#names[*]} -gt 0 ] ||
        "${uc_log:-${LOG?}}" "error" ":load" "Error: no uc-source" \
          "name:$namespec;*:$*" 6 || return
    else
      # Can leave '-' prefix for uc-profile-load to handle
      names=( $namespec )
    fi

    for name in ${names[*]}
    do
      # uc_profile_load already does the same envvar name building,
      # but we want to pick up any setting left by profile here
      : "${name^^}"
      envvar=UC_PROFILE_D_${_//[^A-Z0-9_]/_}
      >/dev/null 2>&1 unset $envvar stat
      uc_profile_load "$name" $type || stat=$?
      local _stat="${!envvar-}"

      # No such file, only list sourced files
      test ${_stat:-0} -eq -1 && continue

      # Append name to list, concat error code if there is one
      names="${names:-}$name${stat:+":E"}${stat-} "

      # XXX: UC_BOOT_ABORT stops at first failing boot-item. Maybe set per-tabline
      #test -z "${stat-}" || {
      #  test $stat -eq $E_UC_PENDING || return $stat
      #}
    done
  done <"$c"
  local context=
  ! uc_debug || context="${names-}"
  "${uc_log:-${LOG?}}" notice ":boot" "Bootstrapped '$*' from user's profile.tab" "$context"
}

# 'Tagged' files are a sort of composite names. Normal acceptible names are
# usually very limited. See the LANANA registries for example: LSB Init script
# names `[-_.a-z0-9]+` and where providers must be `[a-z0-9]+`. Uc-profile uses
# - to add prefix and suffix keys, and uses '_' prefix for local overrides.
# Also Uc-profile uses + and , as a sort of name modifiers, these are tagged
# names.

# At the system level (in /etc/profile.d) the same rules can be applied if
# uc-profile is installed.

uc_profile_dpaths () # ~ <Glob> <Basedir> [<Tags...>]
{
  : "${1:?uc-profile-bootd: Glob expression}"
  : "${2:?uc-profile-bootd: Basedir}"
  local x name{spec,} envvar
  #[[ $# -gt 2 ]] || set --
  for x in ${2}/${1}{,+*,\,*}.sh
  do
    # if we dont have nullglob on...
    [ -e "$x" ] || continue

    : "${x##*/}"
    namespec=${_%.sh}
    # XXX: is basename simply strip of all tags/alts?
    name=${namespec%%[,+]*}
    : "${name^^}"
    envvar=UC_PROFILE_D_${_//[^A-Z0-9_]/_}
    [ -z "${!envvar-}" ] || continue

    if [ -r "$x" ]; then
      echo "$x"
    else
      $LOG warn :acl "$0: $_: no permissions" "$x"
    fi
  done
}

uc_profile__record_env__diff_keys () # ~ FROM TO
{
  test -n "${1-}" || set -- "$(ls "$SD_SHELL_DIR" | head -n 1)" "${2-}"
  test -n "${2-}" || set -- "$1" "$(ls "$SD_SHELL_DIR" | tail -n 1)"
  [[ $# -eq 2 ]] || return ${_E_GAE:-193}
  #args_uc__argc_n :env-diff-keys $# eq 2 || return

  comm -23 "$SD_SHELL_DIR/$2" "$SD_SHELL_DIR/$1"
}

# [4124] TODO: start thinking about building cache files, and backup envs
# when parts arent working; ie. track+report on env status
uc_profile_reboot ()
{
  # Load everything to boot user uc profile
  # (or do whatever required to get a functional session)

  # Current user-conf repo location
  true "${UCONF:="$HOME/.conf"}"

  uc_profile_boot_parts
}

uc_signal_exit ()
{
  local code=${1:-${?:-0}}
  test $code -eq 0 && return 1
  test $code -gt 128 -a $code -lt 162 || return
  exit_signal=$(( code - 128 ))

  signal_names='HUP INT QUIT ILL TRAP ABRT EMT FPE KILL BUS SEGV SYS PIPE ALRM TERM URG STOP TSTP CONT CHLD TTIN TTOU IO XCPU XFSZ VTALRM PROF WINCH INFO USR1 USR2'
  set -- $signal_names
  signal_name=${!exit_signal}
}

# Source file (with UC-DEBUG option and updates ENV-SRC)
uc_source () # ~ [Source-Path]
{
  [ $# -gt 0 ] && [ -n "${1-}" ] || {
    "${uc_log:-${LOG?}}" error ":source" "Expected file argument" "$1"; return 64
  }

  local rs
  . "${1:?}"
  rs=$?
  ENV_SRC="${ENV_SRC:-}${ENV_SRC:+ }$1"

  [ $rs -eq 0 ] && {
    ! uc_debug ||
      "${uc_log:-${LOG?}}" "debug" ":source" "Done sourcing" "$1"
  } || {
   [ $rs -eq ${E_UC_PENDING:?} ] &&
     "${uc_log:-${LOG?}}" "warn" ":source" "Pending (E$rs) sourcing" "$1" ||
     "${uc_log:-${LOG?}}" "error" ":source" "Error (E$rs) sourcing" "$1"
  }
  return $rs
}

# system-source-trace: Helper to format callers list including custom head.
sys_uc_source_trace () # ~ [<Head>] [<Msg>] [<Offset=2>] [ <var-names...> ]
{
  ! "${US_SRC_TRC:-true}" && {
    echo "${1:-us:source-trace: E$? source trace (disabled):}${2+ ${2-}}"
  } || {
    echo "${1:-us:source-trace: E$? source trace:}${2+ ${2-}}" &&
    local i
    for (( i=${1-0}; 1; i++ ))
    do caller $i || break
    done | sed 's/^/  - /'
  }
  [[ 3 -ge $# ]] && return
  echo "Variable context:"
  local -n var &&
  for var in "${@:4}"
  do
    if_ok "$(declare -p ${!var})" &&
    globmatch "declare -n *" "$_" && {
      printf -- '- %s\n  %s\n' "$_" "${!var}: ${var@Q}"
    } || echo "$_"
  done | sed 's/^/  /'
}
# Derive sys

uc_user_init ()
{
  [[ $# -eq 0 ]] || return ${_E_GAE:-193}
  #args_uc__argc :uc-user-init $# || return
  local key= value=
  for key in ${UC_USER_EXPORT:-}
  do
    uc_var_update "$key" || {
      "${uc_log:-${LOG?}}" "error" "" "Missing user env" "$key"
    }
  done
}

uc_var ()
{
  [[ $# -eq 1 ]] || return ${_E_GAE:-193}
  #args_uc__argc :uc-var $# eq 1 || return
  local val upd

  # Force update or try existing value first
  globmatch "* $1 *" " $UC_VAR_PDNG " && {
    uc_var_update "$1"
    upd=1
  }

  val="${!1-}"
  test -z "$val" -a -z "${upd-}" && {
    uc_var_update "$1"
    val="${!1-}"
  }
  test -n "$val" || return

  echo "$val"
}

# Write function to define and update variable value, using given body as
# function body
uc_var_define ()
{
  [[ $# -eq 1 ]] || return ${_E_GAE:-193}
  #args_uc__argc :uc-var-define $# eq 1 || return
  local varname="${1:?}"
  eval "$(cat <<EOM

var_${varname^^}_update ()
{
$(cat)
}

EOM
)"
}

# TODO: deprecate DEFAULT_
uc_var_reset ()
{
  [[ $# -eq 1 ]] || return ${_E_GAE:-193}
  #args_uc__argc :uc-var-reset $# eq 1 || return
  local def_key def_val
  def_key="DEFAULT_${1^^}"
  def_val="${!def_key?Cannot reset user env $1}"
  test -n "$def_val" || return
  eval "$1=\"$def_val\""
}

uc_var_update () # ~ <Var>
{
  [[ $# -eq 1 ]] || return ${_E_GAE:-193}
  #args_uc__argc :uc-var-update $# eq 1 || return
  local varname="${1^^}"
  # XXX: str-upper and lower tooling? (echo "$1" | tr '[:lower:]' '[:upper:]')"
  uc_fun var_${varname}_update && {

    var_${varname}_update || return
  }
  test -n "${!1-}" || uc_var_reset "$1"
}

# XXX: store current val of given,
uc_ctx ()
{
  declare -gA UC_CTX
  sys_aarrv UC_CTX "$@"
}

# 2024 feb: looking at improved envd setup XXX: but cant use arrays outside
# of functions
uc_envd_init ()
{
  # Bootstrap envd-type env if not already initialized
  [[ "set" = "${ENV_TYPE[*]+set}" ]] || {

    . "${UC_LIB_PATH:?}/uc-envd.lib.sh" &&
    envd_lib_init || return
  }

  envd_require uc-host/hostenv uc-ssh/sshenv uc-xdg/deskenv
}


# Misc. functions

append_path () # ~ <DIR> # PATH helper (does not export!)
{
  : source "u-c:script/uc-profile.lib.sh"
  case ":$PATH:" in
    ( *:"${1:?}":* ) ;;
    ( * ) PATH="${PATH:+$PATH:}${1:?}"
  esac
}

os_lookup_add_old () # ~ <Var> <Prepend> <Append>
{
  : source "u-c:script/uc-profile.lib.sh"
  : copy "os.lib.sh"
  [ -e "$2" -o -e "${3-}" ] || {
    >&2 echo "os_path_add: No such file or directory '$*'"
    return 1
  }
  local -n __path=${1?}
  [ -n "${2-}" ] && {
    case "$__path" in
      $2:* | *:$2 | *:$2:* ) ;;
      * ) __path=$2${__path:+:}$__path ;;
    esac
  } || {
    test -n "${2:?}" && {
      case "$__path" in
        $3:* | *:$3 | *:$3:* ) ;;
        * ) __path=$__path${__path:+:}}$3 ;;
      esac
    }
  }
}

# Store variables (name and current value) at associative array
sys_aarrv () # ~ <Array> <Vars...>
{
  : source "u-c:script/uc-profile.lib.sh"
  # XXX: for some reason cannot set var to by-name-ref as well
  declare -n arr=${1:?}
  declare var
  shift
  for var
  do
    arr["${var}"]=${!var}
  done
}
# Copy: sys.lib/system-assoc-array-from-variables

env_keys () # ~
{
  : source "u-c:script/uc-profile.lib.sh"
  # Ignore first line (for '_' value)
  compgen -A variable | sort | tail -n +2
}

if_ok ()
{
  : source "u-c:script/uc-profile.lib.sh"
  return $?
}

sh_fun ()
{
  : source "u-c:script/uc-profile.lib.sh"
  declare -F "${1:?}" > /dev/null
}

sys_astat () # ~ ( <Test-flag> <Test-value> )*
{
  local stat=$?
  while [[ $# -gt 0 ]]
  do
    test $stat "$1" "$2" || return $stat
    shift 2
  done
  : source "u-c:script/uc-profile.lib.sh"
}

# Id: User-Conf:uc-profile.lib
