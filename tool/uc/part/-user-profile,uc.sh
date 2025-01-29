# ~/.profile: executed by the command interpreter for login shells.
#
# This is -user-profile,uc.sh, version XXX.
# Part of a set of generic Bash shell configuration scripts.
#
# Bash: # This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists. See /usr/share/doc/bash/examples/startup-files for examples.
# Debian: These files are distributed in the bash-doc package.

# 2025  Berend van Berkum <dev@dotmpe.com>

if [ -z "$BASH_VERSION" ]
then
  >&2 echo "uc-user-profile.sh is incompatible with shell ${SHELL:-(unspecified)}"
  return
fi

if [[ ! ${uc_env_parts[*]+set} || ! ${uc_env_parts["us-system.g"]+set} ]]
then
  >&2 echo "uc-user-profile.sh did not find host profile; base=${ENV_BASE:-(unspecified)}"
  return
fi

if [[ ! ${uc_log:+set} ]]
then
  >&2 echo "uc-user-profile.sh did not find uc-log setup; base=${ENV_BASE:-(unspecified)}"
  return
fi

### Load user profile parts

ENV_SRC=${ENV_SRC-}${ENV_SRC:+ }${HOME:-~}/.profile

export CAL_DEF=dutch\ german\ debian

### Finally load bashrc

if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -e "$HOME/.bashrc" ]; then
      $uc_log info :user-profile "Loading Bash settings..." "~/.bashrc"
      #shellcheck source=etc/bash/user-rc
      . "$HOME/.bashrc"
    else
      $uc_log debug :user-profile "No Bash settings found" "$BASH_VERSION"
    fi
else
    $uc_log notice :user-profile "Proceeding without Shell RC file"
fi

### Start: finish uc-env loading

[[ "${ENV_BASE:0:7}" != "profile" ]] && {
    $uc_log info "${ENV_CTX}" "Load complete" "~/.profile"
} || {
    $uc_log debug "${ENV_CTX}" "Loaded, starting now" "~/.profile"
    
    # Append metadata and run exports
    uc_env +start profile -- $0 "$@"

    #uc_profile_start

}

# Id: -user-profile,uc ex:ft=bash:
