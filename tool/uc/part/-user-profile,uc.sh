# ~/.profile: executed by the command interpreter for login shells.
#
# This is -user-profile,uc.sh, version XXX.
# Part of a set of generic Bash shell configuration scripts.
#
# Bash: # This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists. See /usr/share/doc/bash/examples/startup-files for examples.
# Debian: These files are distributed in the bash-doc package.

# 2019--2025  Berend van Berkum <dev@dotmpe.com>

ENV_SRC=${ENV_SRC-}${ENV_SRC:+ }${HOME:-~}/.profile

. /srv/conf-local/tool/uconf/part/-uconf-shell-log.sh

if [ "${BASH-}" ] && [ "$BASH" = "/bin/sh" ]; then
  _WARN "user-profile loading in sh-mode! ${SHELL:-(unspecified)}"

elif [ -z "${BASH_VERSION-}" ] && [ -z "${BASH-}" ]; then
  _ALERT "user-profile is incompatible with shell ${SHELL:-(unspecified)}"
  return
fi

if [[ ! ${uc_env_parts[*]+set} || ! ${uc_env_parts["us-system.G"]+set} ]]
then
  _WARN "Warning: -user-profile.sh did not find host profile part; base=${ENV_BASE:-(unspecified)}"
fi

: "${ENV_BASE:=profile}"
: "${ENV_CTX:=$0[$$]:~/.profile}"
if [ -z "${uc_log-}" ]
then
  _IFDBG _ALERT "uc-user-profile.sh did not find uc-log setup; base=${ENV_BASE:-(unspecified)}"
fi

export CAL_DEF=dutch\ german\ debian

### Finally load bashrc
if [ -n "$BASH" ]; then

    # include .bashrc if it exists
    if [ -e "$HOME/.bashrc" ]; then
      ! _uconf_shell_isdebug ||
        _INFO "Loading Bash settings..."
      #shellcheck source=etc/bash/user-rc
      uc_profile_import ~/.bashrc
    else
      _IFDBG _WARN "No Bash settings found"
    fi
else
  _IFDBG _NOTICE "Proceeding without Shell RC file"
fi


### Start profile or signal load ready

[ "${ENV_BASE:0:7}" = "profile" ] && {

  # Append metadata and run exports
  ! declare -F uc_env >/dev/null 2>&1 &&
  _WARN "Missing uc-env profile" ||
    uc_env +start profile -- $0 "$@"

  uc_profile_start

  # The rest is default ~/profile as distributed on Bash-Linux systems, bail.
  return

} || {

  # Nothing to do for a non-login user profile setup
  _IFDB _INFO "Non-login '${USER?}' user shell session"

}

_IFDBG _WARN "Default user profile executing"

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.basher/cellar/bin" ] ; then
    PATH="$HOME/.basher/cellar/packages/bin:$HOME/.basher/cellar/bin:$PATH"
fi

if [ -d "$HOME/.conf/path/Generic" ] ; then
    PATH="$HOME/.conf/path/Generic:$PATH"
fi

if [ -d "$HOME/.conf/path/Linux" ] ; then
    PATH="$HOME/.conf/path/Linux:$PATH"
fi

# XXX: generic calls?
#_IFDBG _INFO "UC profile load complete, starting..."
#
#uc_profile_start
#
_NOTICE "User profile ready"

# Id: -user-profile,uc ex:ft=bash:
