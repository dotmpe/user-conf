# TODO: consolidate into ShellStarr node

[ -n "${BASH_VERSION-}" -o -n "${BASH-}" ] && ENV_SHELL=bash ||
    >&2 echo "-uconf-shell-core.sh is incompatible with ${SHELL-}"

[ "${_uconf_shell_core_-}" = "0" ] || {
  _uconf_shell_core_=1 # Loading core defs...

  . /etc/uc/host
  . /etc/uc/log

  case " ${ENV_BASE-} " in ( *" profile "* )
      # XXX: Reset env
    ;; ( * )
      # Start env
      #. /usr/share/uc/profile,uc.${ENV_SHELL:-sh}

      umask 022
      # Set maximum soft resource limit for user shell processes to 5000
      ulimit -S -u 5000

      : "${USER:=$(whoami)}"
      : "${HOME:=/home/$USER}"
      : "${C_INC:=${HOME}/.l/c}"
      : "${TERM:=dumb}"
      declare -x USER HOME C_INC TERM SHELL=/bin/bash

      # TODO: load just bourne compatible parts for profile, also install somewhere
      #PATH=${PATH:?}:${C_INC:?}/tool/sh/part
      # XXX: start rewriting to compatible namespaces, see common* parts
      PATH=${PATH:?}:${C_INC:?}/tool/us/part

      . "us-profile.inc.bash"
      declare -xf "${us_core_fun[@]}" "${us_shell_profile_fun[@]}" "${us_log_fun[@]}"

      . "us-util.bash"
      declare -xf "${us_util_fun[@]}"

      #_Sys_Apply_Argc 2 us_core_dsl us_debug_profile_dsl \
      #  _Sh_Fun_Eval
      _Sys_Exec_ApplyMap _Sh_Fun_Eval us_core_dsl
      _Sys_Exec_ApplyMap _Sh_Fun_Eval us_debug_profile_dsl

      TODO () {
        failwith "TODO ${FUNCNAME[1]}" 125
      }

      #. "uc-afs.bash"
      . "uc-cmp.bash"
      . "uc-env.bash"

      # For some hosts use user namespaces in profile as well: c-inc
      PATH=${PATH:?}:${C_INC:?}/tool/uc/part

      uc_env @uc/env
      #uc_env +init
      #uc_env -r uconf-shell
  esac

  _uconf_shell_core_=0 # Finish
}

# Id: uc:shell:core $PREFIX/share/uc/-uconf-shell-core.sh           ex:ft=bash:
