# TODO: consolidate into ShellStarr node

[ -n "${BASH_VERSION-}" -o -n "${BASH-}" ] ||
    >&2 echo "-uconf-shell-core.sh is incompatible with ${SHELL-}"

[ "${_uconf_shell_core_-}" = "0" ] || {
  _uconf_shell_core_=1 # Loading core defs...

  >&2 echo "Starting -uconf-shell-core bootstrap"

  . /etc/uc/host
  . /etc/uc/log

  case " ${ENV_BASE-} " in ( *" profile "* )
      # Reset env
    ;; ( * )
      >&2 echo XXX source u-c:-uconf-shell-core.sh

      # Start env
      umask 022
      # Set maximum soft resource limit for user shell processes to 5000
      ulimit -S -u 5000

      # Start env
      : "${USER:=$(whoami)}"
      : "${HOME:=/home/$USER}"
      : "${C_INC:=${HOME}/.l/c}"
      : "${TERM:=dumb}"
      declare -x USER HOME C_INC TERM SHELL=/bin/bash
      PATH=${PATH:?}:${C_INC:?}
      . "uc-env.inc.sh"
      . "uc-cmp.inc.sh"
      . "uc-afs.inc.sh"
      . "uconf-shell.inc.sh"
      . "uconf-shell-core.inc.sh"
      . "uconf-shell-log.inc.sh"
      . "uconf-shell-dsl.inc.sh"
      . "uconf-profile-dsl.inc.sh"
      uc_env @uc/env &&
      true

      #uc_env +init
      #uc_env -r uconf-shell
  esac

  _uconf_shell_core_=0 # Finish
}

# Id: uc:shell:core $PREFIX/share/uc/-uconf-shell-core.sh           ex:ft=bash:
