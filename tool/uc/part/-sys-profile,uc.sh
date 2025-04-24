#
# /etc/profile: system-wide .profile file for the Bourne shell (sh(1))
# and Bourne compatible shells (bash(1), ksh(1), ash(1), ...).
#
# TODO: build seed file, this is copy of uconf:etc/sh/user-profile
# Part of a set of generic Bash shell configuration scripts.
# Id: -uc-global-profile.sh, version:XXX ex:ft=sh:

export UC_SYSLOG_LEVEL=4

ENV_CTX=${ENV_CTX:-$0[$$]:}${ENV_CTX:+ }profile

case "${0##*/}" in
  ( *-session | Xsession ) export QUIET=true ;;
esac

export uc_stat=return

. /srv/conf-local/tool/uconf/part/-uconf-shell-log.sh

if [ "${BASH-}" ] && [ "$BASH" = "/bin/sh" ]; then
  _WARN "-uc-system-profile.sh loading in sh-mode! ${SHELL:-(unspecified)}"
fi

if [ -n "${ENV_BASE-}" ]
then
  _ALERT "-uc-system-profile.sh recursive call ${ENV_BASE:?}"
  #return
fi

if [ -n "${BASH_VERSION-}" ] || [ -n "$BASH" ]; then
  # Initialize from uc-dump if not already done
  2>&1 >/dev/null declare -F uc_env_continue && {
    uc_env_continue &&
    _INFO "Continued existing uc-env" ||
      _ERR "Failed to resume existing uc-env: E$?"
  } || {
    _DEBUG "No uc-env found yet, waiting for interactive or static init to complete"
    declare -gA uc_env_{hooks,parts,types}
    declare -ga uc_env_{locals,exports}
    # Wait for us-system to load, later
  }
else
  _WARN "Cannot start uc-env for unknown shell ${SHELL-(unset)}"
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

fnmatch ()
{
  : copy "str.lib.sh"
  _IFDBG _ALERT "Deprecated: ${FUNCNAME[*]}"
  case "$2" in $1 ) return 0 ;; *) return 1 ;; esac
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
if [ "$(id -u)" -eq 0 ]; then
  PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
else
  PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"
fi
export PATH

[ -z "${BASH-}" ] && {
  _ALERT "Unknown shell, no uc-profile available"

} || {
  ! _uconf_shell_isdebug ||
    _INFO "Starting Bash uc-profile"

  export -f append_path add_path fnmatch

  . /etc/profile.d/uc-profile.sh ||
    _FATAL "Expected uc-profile.sh part installed" || return

  [ -n "${LOG-}" ] || {
    uc_log_init && LOG=uc_log ||
      _WARN "Failed interactive log init (ignored): E$?"
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

  ! _uconf_shell_isdebug ||
  _DEBUG "Acquired LOG=$LOG"
}

## Load shell settings
if [ "${PS1-}" ]; then
  if [ "${BASH-}" ] && [ "$BASH" != "/bin/sh" ]; then

    . /etc/profile.d/us-system.sh ||
      _FATAL "Expected uc-system.sh part installed" || return

    # The file bash.bashrc already sets the default PS1.
    # PS1='\h:\w\$ '
    if [ -f /etc/bash.bashrc ]; then
      . /etc/bash.bashrc ||
        _ERR "Bash system rc returned non-zero: E$? (ignored)"
    else
      _ALERT "Bash system rc missing!"
    fi
  else
    if [ "$(id -u)" -eq 0 ]; then
      PS1='# '
    else
      PS1='$ '
    fi
    ! _uconf_shell_isdebug ||
      _DEBUG "Configured PS1 for other shells"
  fi
else
  ! _uconf_shell_isdebug ||
    __DEBUG "Not interactive, no PS1 setting"
fi


## Load all system profile parts

# Normally, /etc/profile loads /etc/profile.d/*.sh here. But uc-profile uses
# tagged files, and potentially files from other directories as well. Still,
# there is a difference between sourcing in a function and sourcing in the
# global scope: declare statements are (default) global or local.



# XXX: for systems that cannot control what is in /etc/profile.d (ie. need to
# deal with incompatible source files) the source must be inline here.

# But uc-profile instead uses a utility function here: to load all names from
# the primary includes directory.


if [ "${BASH-}" ] && [ "$BASH" != "/bin/sh" ] || [ -n "${BASH_VERSION-}" ]
then
  ! _uconf_shell_isdebug ||
    _DEBUG "Starting primary profile.d source sequence"

  : "${UC_PROFILE_D%%:*}"
  mapfile -t ucp_paths <<< "$(uc_profile_dpaths '*' "$_")"
  for i in "${ucp_paths[@]}"
  do
    if [ -r $i ]; then

      . $i && {
        ! _uconf_shell_isdebug || {
          : "${BASH_SOURCE[$(( ${#BASH_LINENO[*]} - 1 ))]}"
          $LOG debug :source "$0: $_: source complete" "$i"
        }
      } || { s=$?
        # TODO: rename incubator to US2,
        #"${US_DEV:-false}" ||
        #"${US_STRICT:-false}" ||
        #"${DEBUG:-false}" || continue

        : "${BASH_SOURCE[$(( ${#BASH_LINENO[*]} - 1 ))]}"
        _WARN "$0: $_: source returned non-zero E$s:$i (ignored)"
      }
    fi
  done
  ! _uconf_shell_isdebug ||
    _INFO "Finished ${#ucp_paths[*]} profile.d sources"
  unset i s ucp_paths

else
  ! _uconf_shell_isdebug ||
    _INFO "Starting primary profile.d source sequence (non-Bash)"

  # Run the normal non-Bash profile.d sequence
  if [ -d /etc/profile.d ]; then
    # TODO: add to ENV_BASE? or track otherwise
    # XXX: read overrides instead
    for i in /etc/profile.d/*.sh; do
      if [ -r $i ]; then
        . "$i" && {
          ! _uconf_shell_isdebug ||
            _DEBUG "profile.d source complete" "$i"
        } || { s=$?
          _WARN "profile.d source failed" "E$s:$i"
        }
      fi
    done
    unset i s
  fi
  ! _uconf_shell_isdebug ||
    _DEBUG "Finished profile.d source sequence"
fi

# NOTE: this user-conf profile is incomplete. Intentionally as this is the
# global system part, and the user-profile part loaded after this should kick
# things off.

# TODO: uc-env-{export,init,start} trigger env, see home/user parts

_IFVBS _NOTICE "System profile finished"

# ex:ft=sh:
