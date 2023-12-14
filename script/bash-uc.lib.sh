#!/usr/bin/env bash

# XXX: cleanup
# [2022-01-29] Tried getting bashdb but only works with 4.1, have Bash 5
	#shopt -s extdebug
#  stacktrace
#  return

  #set +o xtrace

# Auto-install trap for Bash when in debug mode.
bash_uc_lib__init ()
{
  test -z "${bash_uc_lib_init-}" || return $_
  # FIXME: set std mode, track modes somewhere
  #sh-mode strict
  set -euo pipefail || return

  ! ${SH_DEBUG:-${DEBUG:-false}} && {
    true
  } || {
    #sh-mode dev # Enable shell stacktrace print on errexit
    set -hET &&
    shopt -s extdebug &&
    trap 'bash_uc_errexit' ERR || return
  }
}

bash_env_exists () # ~ NAMES...
{
  declare -p "$@" >&2 2>/dev/null
}
#alias is-var=bash_env_exists

# Return file:number
bash_caller ()
{
  caller
}

bash_uc_errexit ()
{
  local err=$? n=${NORMAL-} b=${BOLD-} r=${REVERSE-}

  # Adding color makes things a mess, this is the best I will now for now
  : ${_1:=${RED-}}
  : ${_1_1:=${n}${b}${RED-}}
  : ${_1_2:=${r}}
  : ${_2:=${WHITE-}}
  : ${_2_1:=${b}}
  : ${_3:=${n}${b}}
  : ${_3_1:=${_3}}
  : ${_4:=${b}${BLACK-}}
  : ${_4_1:=${_4}}
  : ${_5:=${n}${GREEN-}}
  : ${_5_1:=${_4}}
  : ${_5_1_1:=${_5_1}}
  : ${_5_2:=${_5}}
  : ${_6:=${n}${b}}
  : ${_6_1:=${_4}}
  : ${_6_2:=${_6_1}}

  : ${BASH_SCRIPTNAME:=Bash}

  {
    # Print error-line and stack-trace
    printf " ${_1}${_1_2} ${_1_1} ${_1}${BASH_SCRIPTNAME} error:${n} ${_3_1}'${_3}${BASH_COMMAND}${_3_1}' ${_2}exited with status ${_2_1}$err"
    # TODO: If str/argv are loaded, run some user-configured errexit handles as well
    #: "${SHELL_NAME:=$(basename -- $SHELL)}"
    #printf "    ${b}${_f0}${r}${b}"
    #printf '%-'$(tput cols)'s' ""
    #printf "$(date) $USER@$HOST $SHELL_NAME[$$] ${n}\n"
    printf "${n}\n"

    {
      # Shell option required for BASH_ARGV
      shopt -q extdebug
    } && {
      {
        case "$-" in ( *E* ) ;; ( * ) false ;; esac &&
        case "$-" in ( *T* ) ;; ( * ) false ;; esac
      } || {
        $LOG warn ":bash-uc.lib:errexit" "Cannot display full trace without E/T?" "-=$-"
      }
    } || {
      # Bash manual notes setting extdebug after starting script or not at all
      # results in inconsistant values. Would probably want some framework/env
      # setting to guarantee consistent ops.
      $LOG error ":bash-uc.lib:errexit" "Cannot display trace without extdebug mode" "-=$-"
      #return 1
    }
#
    declare frame=0
    declare bash_argv_offset=0

    while caller_info=( $(caller $frame) )
    do
      declare argv=()
      declare argc
      declare frame_argc

      bash_frame_argc=${BASH_ARGC[frame]:--1}
      test "$bash_frame_argc" != "-1" && {
        for ((frame_argc=$bash_frame_argc,frame_argc--,argc=0; frame_argc >= 0; argc++, frame_argc--)) ; do
          argv[argc]=${BASH_ARGV[argv_offset+frame_argc]}
          case "${argv[argc]}" in
              *[[:space:]]*) argv[argc]="'${argv[argc]}'" ;;
          esac
        done
        argv_offset=$((argv_offset + ${BASH_ARGC[frame]}))
      }

      #if [ $frame -eq 0 ]
      #then
        # The last (top) 'function' on the stack will be the trap handler (it
        # is on the correct line, where the parser left off/failed. But it is
        # not the failed command, but the name for the handler that Bash called
        # for the ERR-trap. Also no argv for either seems to be available at all).
        #
        # But the handler worked fine.
        # Since we don't need or want to see that error handler name, replace it
        # instead with the actual command that Bash said has failed so there is
        # no confusion about what worked and what failed.
      #  cmd="${_6}'$BASH_COMMAND' "
      #else
        cmd="${_6}${FUNCNAME[$frame]}${_6_1} ${_6_2}$(printf '%s ' "${argv[@]}")${_6_1}"
      #fi

      echo "    ${_4}$frame${_4_1}. ${n}${caller_info[1]}${_4_1}(): ${n}$cmd$n ${_5_1}<${_5}${caller_info[2]}${_5_1_1}:${_5_2}${caller_info[0]}${_5_1}>$n"

      frame=$((frame+1))
    done

  } >&2
  return "${1:-1}"
}

#
