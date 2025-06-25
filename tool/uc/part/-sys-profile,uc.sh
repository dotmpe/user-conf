#
# /etc/profile: system-wide .profile file for the Bourne shell (sh(1))
# and Bourne compatible shells (bash(1), ksh(1), ash(1), ...).
#
# The system profile configuration sets up a login shell session, and exports
# the environment for a user. For new user shell session, only the rc file
# should be sourced (but only for interactive sessions normally). uc integrates
# everything using the us-system.sh group and uc-env tools.
#
# No this isn't POSIX compatible scripting, and it is really written for Bash
# shells (currently).
#
# TODO: build seed file, this is copy of uconf:etc/sh/user-profile
# Part of a set of generic Bash shell configuration scripts.
# Id: -uc-global-profile.sh, version:XXX ex:ft=sh:


ENV_CTX=${ENV_CTX:-$0[$$]}

[ "${_uconf_shell_core_-}" = "0" ] || {
  [ -r /etc/uc ] &&
  [ -n "${BASH_VERSION-}" -o -n "${BASH-}" ] || return

  . /usr/share/uc/-uconf-shell-core.sh
}

ENV_CTX=${ENV_CTX}-login

_etc_profile=/etc/profile,uc
_etc_profile_a=id
_etc_profile_id=user-conf:$_etc_profile

_NOTICE "Starting system login shell"

_IFDBG _DEBUG "$_etc_profile: System login env user $USER \$ $$ [-$-] $0 (#$#) ~ $*"

if [ "${BASH-}" ] && [ "$BASH" = "/bin/sh" ]; then
  _WARN "$_etc_profile: loading in sh-mode! ${SHELL:-(unspecified)}"
fi

# Start uc env groups

if [ -n "${ENV_BASE-}" ] && :fnMatch "* profile *" " $ENV_BASE "
then
  _ALERT "$_etc_profile: recursive call ${ENV_BASE:?}"
  return
fi

uc_env @part G profile /etc/profile
uc_env @part G uc-env-core /usr/share/uc/-uconf-shell-core.sh

uc_env -r us-bwc-dx


## Reset PATH value

# FIXME: A login shell needs to setup for the correct user, and so is what
# /etc/profile should manage. But uc will also try to continue an existing
# context if we inherit one (from exports), and will assume the PATH is exported
# and valid too.

if [ -z "${PATH-}" ] || [ "${PATH-}" = /usr/local/bin:/usr/bin:/bin:/usr/games ]
then
  if [ "$(id -u)" -eq 0 ]; then
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  else
    PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"
  fi
  export PATH
fi


## Preload env for user rc

[ -z "${BASH-}" ] && {
  _ALERT "$_etc_profile: Unknown shell, no uc-profile available!"

} || {

  _ _IFDBG _INFO "$_etc_profile: Starting Bash uc-profile"

  . /etc/profile.d/uc-profile.sh ||
    _ALERT "$_etc_profile: Unexpected uc-profile.sh E$?" || return

  [ -n "${LOG-}" ] || {
    uc_log_init && LOG=uc_log ||
      _WARN "$_etc_profile: Failed interactive log init (ignored): E$?"
  }

  # XXX: If non-interactive (or interactive setup fails), try static config and export working LOG now.
  #LOG=/etc/profile.d/uc-profile.sh
  #test -e "$LOG" || LOG=${UC_PROFILE_SELF-}
  #test ! -x "$LOG" && {
  #  # Something amiss.. but nothing to do about it.
  #  # Can't export LOG but can help other UC files to load
  #  export UC_E_NOLOG=1
  #  uc_log=$(which true)

  #} || {
  #  # Load UC-profile config and set env, try log event
  #  eval "$($LOG env)" && {
  #    $LOG "info" ":sys-profile" "New shell logger started" "${!UC_*}"
  #  } || {
  #    _ALERT "Failed uc-log eval: E$?"
  #    # Something is wrong, don't even try to get a logger or anything else fancy anymore. Use what we have.
  #    export UC_FAILLOG=1
  #  }
  #  export LOG
  #  uc_log=$LOG
  #}

  _IFDBG _DEBUG "$_etc_profile: Acquired LOG=$LOG"
}

## Load shell settings ('rc' group)
if [ "${PS1-}" ]; then
  if [ "${BASH-}" ] && [ "$BASH" != "/bin/sh" ]; then
    : "${PS1:='\h:\w\$ '}"
    if [ -f /etc/bash.bashrc ]; then
      . /etc/bash.bashrc ||
        _ _ERR "$_etc_profile: Bash system rc returned non-zero: E$? (ignored)"
    else
      _ _ALERT "$_etc_profile: Bash system rc missing!"
    fi
  else
    if [ "$(id -u)" -eq 0 ]; then
      PS1='# '
    else
      PS1='$ '
    fi
    _ _IFDBG _DEBUG "$_etc_profile: Configured PS1 for other shells"
  fi
else
  _ _IFDBG _DEBUG "$_etc_profile: Not interactive, no PS1 setting"
fi


## Load all system profile parts

# Normally, /etc/profile loads /etc/profile.d/*.sh here. But uc-profile uses
# tagged files, and potentially files from other directories as well. Also,
# there is a difference between sourcing in a function and sourcing in the
# global scope: declare statements are (default) global or local.

# XXX: for systems that cannot control what is in /etc/profile.d, wrapping in a
# function could break some scripts (ie. those using declare, but expecting
# global is default).

# uc-profile instead uses a utility function here
# to load all names from the primary includes directory.


if [ "${BASH-}" ] && [ "$BASH" != "/bin/sh" ] || [ -n "${BASH_VERSION-}" ]
then
  _IFDBG _DEBUG "$_etc_profile: Starting primary profile.d source sequence"

  : "${UC_PROFILE_D%%:*}"
  mapfile -t ucp_paths <<< "$(uc_profile_dpaths '*' "$_")"
  for i in "${ucp_paths[@]}"
  do
    if [ -r $i ]; then

      . $i && {
        _IFDBG _DEBUG "$_etc_profile: $i: Source complete"
      } || { s=$?
        _WARN "$_etc_profile: source returned non-zero E$s:$i (ignored)"
      }
    fi
  done
  _IFDBG _INFO "$_etc_profile: Finished ${#ucp_paths[*]} profile.d sources"
  unset i s ucp_paths

else
  _ _IFDBG \
    _INFO "$_etc_profile: Starting primary profile.d source sequence (non-Bash)"

  # Run the normal non-Bash profile.d sequence
  if [ -d /etc/profile.d ]; then
    # TODO: add to ENV_BASE? or track otherwise
    # XXX: read overrides instead
    for i in /etc/profile.d/*.sh; do
      if [ -r $i ]; then
        . "$i" && {
          _IFDBG _DEBUG "$_etc_profile: profile.d source complete" "$i"
        } || { s=$?
          _WARN "$_etc_profile: profile.d source failed" "E$s:$i"
        }
      fi
    done
    unset i s
  fi
  _IFDBG _DEBUG "$_etc_profile: Finished profile.d source sequence"
fi

# NOTE: this user-conf profile is incomplete, as uc-env isnt initialized yet.
# That is intentionally as this is always the global system part, and a per user
# profile part loaded after this should kick things off.

# TODO: uc-env-{export,init,start} trigger env, see home/user parts
# should finalize etc-profile group here, to indicate it finished properly
_NOTICE "System profile ($_etc_profile) finished"

# Id: uc:sys:profile /etc/profile ex:ft=bash:
