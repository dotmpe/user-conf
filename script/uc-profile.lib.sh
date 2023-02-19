#shellcheck disable=SC2120 # Ignore, argv_uc__argc is doing some checks

# Helper to source libs only once
uc_profile_load_lib ()
{
  test -n "${UC_PROFILE_SRC_LIB-}" || {
    uc_profile_source_lib || return
  }
}

# XXX: load first tools/sh/profile
uc_profile_boot_parts ()
{
  for bd in ${UC_BOOT_PATH:-${UCONF:?} ${U_C:?}}
  do
    test -s "$bd/tools/sh/profile.sh" || continue
    #shellcheck source=tools/sh/profile.sh
    . "$bd/tools/sh/profile.sh"
    break
  done
  unset bd
}

#shellcheck disable=1091 # Cannot add source directives here
# Source all libs
uc_profile_source_lib () # ~
{
  UC_PROFILE_SRC_LIB=1

  # This is not so nice but there's too many functions involved.
  # XXX: Keep this file stable. Move essentials here, later probably?
  # Should maybe mark some and keep (working) caches
  #  Or mark these libs as 'global'
  . "$UC_LIB_PATH"/shell-uc.lib.sh &&
  shell_uc_lib_init &&
  . "$UC_LIB_PATH"/str-uc.lib.sh &&
  . "$UC_LIB_PATH"/argv-uc.lib.sh &&
  . "$UC_LIB_PATH"/stdlog-uc.lib.sh &&
  stdlog_uc_lib_load &&
  . "$UC_LIB_PATH"/ansi-uc.lib.sh &&
  ansi_uc_lib_load &&
  . "$UC_LIB_PATH"/syslog-uc.lib.sh &&
  syslog_uc_lib_load &&

  ansi_uc_lib_init &&
  #stdlog_uc_lib_init &&
  #syslog_uc_lib_init &&

  UC_PROFILE_SRC_LIB=0
}

# Set Id for shell session. This should be run first thing,
# when next to no profile whatsoever has been loaded.
uc_profile_init () # ~
{
  uc_profile_load_lib || return

  argv_uc__argc :init $# eq 1 || return

  set -- $(hostname -s) $USER $(basename -- "$SHELL") $$ "$1"
  set -- $(printf '%s:' "$@")
  export UC_SH_ID="${1:0:-1}"

  # Comply with dynamic init of non-interactive shell, but be more cautious
  test -z "${PS1-}" && {
    # Don't try to exit in the middle of a script
    UC_LOG_EXITS=-1
  } || {

    # Some RC stuff
    test -z "${BASH}" || {
      set -h # Remember the location of commands as they are looked up. (same as hashall)
      set -E # If set, the ERR trap is inherited by shell functions.
      set -T
      set -e
      set -u # Treat unset variables as an error when substituting. (same as nounset)
      set -o pipefail #
      shopt -s extdebug
    }
  }

  uc_log_init && {
    $uc_log "info" ":init" "U-c profile init has started dynamic shell setup" "-:$-"
    : "${LOG:=uc_log}"

  } || {
    # Something's already wrong, see if log works or fail Uc-profile init completely.
    LOG="${UC_PROFILE_SELF}"
    $LOG "warn" ":init" "U-c profile init has failed dynamic setup" "-:$-" || {
      export UC_FAIL=1
    }
  }

  test "0" = "${UC_FAIL:-0}" || return
  $uc_log "info" ":init" "U-c profile init proceeding"

  UC_PROFILE_INIT=1
}

# Finalize init for shell session
uc_profile_start () # ~
{
  argv_uc__argc :start $# || return

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

  $uc_log "notice" ":start" "Session ready" "$ctx"
}

# Add parts to shell session
uc_profile_load () # ~ NAME [TAG]
{
  argv_uc__argc :load $# gt || return

  local exists=1 name="$1" envvar ret
  fnmatch "\**" "$1" && {
    exists=0; name="$(echo "$1" | cut -c2-)"
  }
  shift
  envvar=UC_PROFILE_D_$(echo "$name" | tr '[:lower:]' '[:upper:]')

  # Skip if already loaded
  test -z "$(eval "echo \"\${$envvar-}\"")" || return 0
  #test -z "${!envvar-}" || return 0

  # During loading UC_PROFILE_D_<name>=1, and at the end it is set to the source return status.
  # However the script itself....
  eval $envvar=-1

  # During source of the env file, `uc_profile_load{,_path,_tag}` can be referred to.

  local uc_profile_load="$1" uc_profile_tag="${2:-}"

  local uc_profile_load_path=$( for profile_d in $(echo $UC_PROFILE_D | tr ':' ' ');
      do
          test -e "$profile_d/$name.sh" || continue
          printf '%s' "$profile_d/$name.sh"
          break
      done )

  # Bail if no such <name> profile exists
  test -e "$uc_profile_load_path" || {
    # error unless '*<name>' was specified
    test $exists -eq 0 && return 255
    $uc_log "error" ":load" "Error: no uc-source" "$name"
    return 6
  }

  $uc_log debug ":load" "Loading part" "$*:$name"
  uc_source "$uc_profile_load_path"
  ret=$?

  local _stat="$(eval "echo \"\${$envvar-}\"")"

  # File exists, so we have a status either way
  test "${_stat}" != "-1" || unset $envvar

  # If non-zero and not pending, set UC_PROFILE_D_<name> to status.
  # Otherwise return pending directly and unset UC_PROFILE_D_<name>
  test $ret -eq 0 || {
    test $ret -eq $E_UC_PENDING && {
      return $E_UC_PENDING
    }
  }

  eval $envvar=$ret
  return $ret
}

# End shell session
uc_profile_cleanup ()
{
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
      $uc_log "warn" ":cleanup" "Some command exited after signal $signal_name ($exit_signal) [$rs]"
    } || $uc_log "warn" ":cleanup" "Some command exited with code [$rs]"
  }
  uc_profile_cleanup
}

uc_profile_cleanup_BASH ()
{
  local lc="$BASH_COMMAND" rs=${?:-0}
  test $rs -eq 0 || {
    uc_signal_exit $rs && {
      $uc_log "warn" ":cleanup" "Command [$lc] exited after signal $signal_name ($exit_signal) [$rs]"
    } || $uc_log "warn" ":cleanup" "Command [$lc] exited with code [$rs]"
  }
  uc_profile_cleanup
}

# Source file (with UC-DEBUG option and updates ENV-SRC)
uc_source () # ~ [Source-Path]
{
  test $# -gt 0 -a -n "${1-}" || {
    $uc_log error ":source" "Expected file argument" "$1"; return 64
  }

  local rs
  . "$1"
  rs=$?
  ENV_SRC="$ENV_SRC$1 "

  test $rs -eq 0 && {
    test -z "${USER_CONF_DEBUG-}" ||
      $uc_log "debug" ":source" "Done sourcing" "$1"
  } || {
   test $rs -eq $E_UC_PENDING ||
     $uc_log "error" ":source" "Error ($rs) sourcing" "$1"
  }
  return $rs
}

# Same as uc-source but also take snapshot of env vars name-list
uc_import () # ~ [Source-Path]
{
  uc_source "$@" || return
  uc_profile__record_env__keys $(echo "$1" | tr '/' '-' | uc_mkid)

  # TODO: record ENV-SRC snapshot as well.
  test -z "${USER_CONF_DEBUG-}" ||
    $uc_log warn ":import" "New env loaded, keys stored" "$1"
}

# Besides init/start/end this is the mayor step of UC-profile, performed
# one or several times during shell init. For this reason this should never
# return an error.
uc_profile_boot () # TAB [types...]
{
  test -n "${1-}" || -- set $UC_TAB $*
  test -s "${1-}" || {
    $uc_log "crit" ":boot" "Missing or empty profile table" "${1-}"
    return
  }

  test $# -gt 0 -a -e "${1-}" || return 64
  local tab="$1"; shift 1

  test $# -gt 0 && UC_PROFILE_TP="$*" || set -- ${UC_PROFILE_TP:?}

  local c="${UC_RT_DIR}/user-$(id -u)-profile.tab"
  test ! -e "$c" -o "$c" -ot "$tab" && {
    grep -v -e '^ *#' -e '^ *$' "$tab" >"$c"
  }

  test ! -e "$c" -o "$c" -ot "$tab" && {
    grep -v -e '^ *#' -e '^ *$' "$tab" >"$c"
  }

  $uc_log "info" ":boot" "Start sourcing profile.tab parts" "$*:wcl=$(wc -l "$c")"

  local name type
  while read name type
  do
    test -n "$type" -a $# -gt 0 && {
      # Skip entry unless '$*' matches any type for entry
      local tp m=0
      for tp in "$@"; do fnmatch "* $tp *" " $type " && m=1 || continue; done

      test $m -eq 1 || {
        test -z "${USER_CONF_DEBUG-}" ||
          $uc_log warn ":boot<>$name" "Skipped profile.tab entry" "$type not in $*"
        continue
      }
    }

    # uc_profile_load already does the same envvar name building,
    # but we want to pick up any setting left by profile here
    fnmatch "\**" "$name" && rname=$(echo $name | cut -c2-) || rname=$name
    envvar=UC_PROFILE_D_$(echo "$rname" | tr '[:lower:]' '[:upper:]')

    unset stat $envvar 2>&1 > /dev/null
    uc_profile_load "$name" $type || stat=$?

    local _stat="$(eval "echo \"\${$envvar-}\"")"

    # No such file, only list sourced files
    test ${_stat:-0} -eq -1 && continue

    # Append name to list, concat error code if there is one
    names="${names:-}$name${stat:+":E"}${stat-} "

    # XXX: UC_BOOT_ABORT stops at first failing boot-item. Maybe set per-tabline
    #test -z "${stat-}" || {
    #  test $stat -eq $E_UC_PENDING || return $stat
    #}
  done <"$c"
  $uc_log notice ":boot" "Bootstrapped '$*' from user's profile.tab" "${names-}"
}

uc_user_init ()
{
  argv_uc__argc :uc-user-init $# || return
  local key= value=
  for key in ${UC_USER_EXPORT:-}
  do
    uc_var_update "$key" || {
      $uc_log "error" "" "Missing user env" "$key"
    }
  done
}

uc_var_reset ()
{
  argv_uc__argc :uc-var-reset $# eq 1 || return
  local def_key def_val
  def_key="DEFAULT_$(echo "$1" | tr '[:lower:]' '[:upper:]')"
  def_val="${!def_key?Cannot reset user env $1}"
  test -n "$def_val" || return
  eval "$1=\"$def_val\""
}

uc_var_update ()
{
  argv_uc__argc :uc-var-update $# eq 1 || return
  local varname="$(echo "$1" | tr '[:lower:]' '[:upper:]')"
  uc_func var_${varname}_update && {

    var_${varname}_update || return
  }
  test -n "${!1-}" || uc_var_reset "$1"
}

uc_var_define ()
{
  argv_uc__argc :uc-var-define $# eq 1 || return
  local varname="$(echo "$1" | tr '[:lower:]' '[:upper:]')"
  eval "$(cat <<EOM

var_${varname}_update ()
{
$(cat)
}

EOM
)"
}

# Record env keys only; assuming thats safe, no literal dump b/c of secrets
uc_profile__record_env__keys ()
{
  argv_uc__argc_n :record-env:keys $# eq 1 || return
  test ! -e "$SD_SHELL_DIR/$UC_SH_ID:$1.sh" || {
    $uc_log "error" ":record-env:keys" "Keys already exist" "$1"
    return 1
  }
  env_keys > "$SD_SHELL_DIR/$UC_SH_ID:$1.sh"
}

uc_profile__record_env__ls ()
{
  argv_uc__argc_n :record-env-ls $# || return
  for name in "$SD_SHELL_DIR/$UC_SH_ID"*
  do
    echo "$(ls -la "$name") $( count_lines "$name") keys"
  done
}

env_keys() # ~
{
  argv_uc__argc :env-keys $# || return
  printenv | sed 's/=.*$//' | grep -v '^_$' | sort -u
}

uc_profile__record_env__diff_keys () # ~ FROM TO
{
  test -n "${1-}" || set -- "$(ls "$SD_SHELL_DIR" | head -n 1)" "${2-}"
  test -n "${2-}" || set -- "$1" "$(ls "$SD_SHELL_DIR" | tail -n 1)"
  argv_uc__argc_n :env-diff-keys $# eq 2 || return

  comm -23 "$SD_SHELL_DIR/$2" "$SD_SHELL_DIR/$1"
}

uc_mkid () # ~
{
  argv_uc__argc :env-keys $# || return
  tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]'
}

# TODO: replace these with sh_env either from shell-uc.lib or shell.lib
uc_func ()
{
  argv_uc__argc :uc-func $# eq 1 || return
  test "$(type -t "$1")" = "function"
}

uc_cmd ()
{
  argv_uc__argc :uc-cmd $# eq 1 || return
  test -x "$(command -v "$1")"
}

uc_var ()
{
  argv_uc__argc :uc-var $# eq 1 || return
  local val upd

  # Force update or try existing value first
  fnmatch "* $1 *" " $UC_VAR_PDNG " && {
    uc_update "$1"
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

# Id: User-Conf:uc-profile.lib
