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

ENV_CTX=${ENV_CTX:-$0[$$]:}${ENV_CTX:+ }profile

. /usr/share/uc/-uconf-shell-core.sh

_etc_profile=/etc/profile,uc
_etc_profile_a=id
_etc_profile_id=user-conf:$_etc_profile

_IFDBG _DEBUG "$_etc_profile: System login env user $USER \$ $$ [-$-] $0 (#$#) ~ $*"

if [ "${BASH-}" ] && [ "$BASH" = "/bin/sh" ]; then
  _WARN "$_etc_profile: loading in sh-mode! ${SHELL:-(unspecified)}"
fi

if [ -n "${ENV_BASE-}" ] && fnmatch "* profile *" " $ENV_BASE "
then
  _ALERT "$_etc_profile: recursive call ${ENV_BASE:?}"
  return
fi

if [ -n "${BASH_VERSION-}" ] || [ -n "$BASH" ]; then
  # Managed by uc.
  is_fun uc_env_continue && {
    # Initialize from uc-dump if not already done
    uc_env_continue &&
    _INFO "$_etc_profile: Continued existing uc-env" || {
      _ERR "$_etc_profile: Failed to resume existing uc-env: E$?" ||
        ${uc_stat:-return} $?
    }
  } || {

    _IFDBG _DEBUG \
    "$_etc_profile: No uc-env found yet, waiting for interactive or static init to complete"
    declare -gA uc_env_{hooks,parts,types}
    declare -ga uc_env_{locals,exports}
    # Wait for us-system to load, later
  }
else
  _WARN "$_etc_profile: Cannot start uc-env for unknown shell ${SHELL-(unset)}"
fi

# TODO: check if already on...
#: "${ENV_BASE:=profile}"
ENV_BASE=${ENV_BASE-}${ENV_BASE:+ }profile
ENV_SRC=${ENV_SRC-}${ENV_SRC:+ }/etc/profile


# I prefer os_path_add or even add_path but this is default (on Debian)
append_path () # ~ <DIR> # PATH helper (does not export PATH!)
{
  : source "/etc/profile"
  add_path "$@" ||
    test 1 -eq $? || return $_
}

add_path ()
{
  : about "Simple PATH helper to append only new, unique instance"
  : param "<DIR>" "Should be a directory, but this is not verified"
  : extended "Using this helps keeping PATH cleaner, but it is intentionally a "
  : extended "very simple implementation of this type of heuristic. "
  : extended "For similar functions see uc and us sys.lib add-env-path"
  : notes TODO "Really should write sys-wordv-add or something"
  : notes XXX "This does not export PATH"
  : notes : "Exactly the same implementation as shipped with Debian/Ubuntu"
  : source "/etc/profile"
  case ":$PATH:" in
  ( *:"${1:?}":*) # XXX: false
    ;;
  ( * )
      PATH="${PATH:+$PATH:}${1:?}"
  esac
}


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
  export -f append_path add_path fnmatch

  _IFDBG _INFO "$_etc_profile: Starting Bash uc-profile"

  . /etc/profile.d/uc-profile.sh ||
    _FATAL "$_etc_profile: Expected uc-profile.sh part installed" || return

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

## Load shell settings
if [ "${PS1-}" ]; then
  if [ "${BASH-}" ] && [ "$BASH" != "/bin/sh" ]; then

    . /etc/profile.d/us-system.sh ||
      _FATAL "$_etc_profile: Expected uc-system.sh part installed" || return

    : "${PS1:='\h:\w\$ '}"
    if [ -f /etc/bash.bashrc ]; then
      . /etc/bash.bashrc ||
        _ERR "$_etc_profile: Bash system rc returned non-zero: E$? (ignored)"
    else
      _ALERT "$_etc_profile: Bash system rc missing!"
    fi
  else
    if [ "$(id -u)" -eq 0 ]; then
      PS1='# '
    else
      PS1='$ '
    fi
    _IFDBG _DEBUG "$_etc_profile: Configured PS1 for other shells"
  fi
else
  _IFDBG _DEBUG "$_etc_profile: Not interactive, no PS1 setting"
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
        : "${BASH_SOURCE[$(( ${#BASH_LINENO[*]} - 1 ))]}"
        _IFDBG _DEBUG "$_etc_profile: $_: Source complete"
      } || { s=$?
        # TODO: rename incubator to US2,
        #"${US_DEV:-false}" ||
        #"${US_STRICT:-false}" ||
        #"${DEBUG:-false}" || continue

        : "${BASH_SOURCE[$(( ${#BASH_LINENO[*]} - 1 ))]}"
        _WARN "$_etc_profile: $_: source returned non-zero E$s:$i (ignored)"
      }
    fi
  done
  _IFDBG _INFO "$_etc_profile: Finished ${#ucp_paths[*]} profile.d sources"
  unset i s ucp_paths

else
  _IFDBG \
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

_IFVBS _NOTICE "System profile ($_etc_profile) finished"

# ex:ft=sh:
