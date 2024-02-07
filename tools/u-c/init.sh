#!/usr/bin/env bash


true "${U_S:?Requires User-Script installation}"
true "${UC_LIB_PATH:?Expected UC shell lib}"

#test -n "${LOG-}" || LOG=/etc/profile.d/uc-profile.sh
true "${LOG:=${U_C:?}/tools/sh/log.sh}"
export LOG
INIT_LOG=$LOG

. "$U_S/src/sh/lib/shell.lib.sh"
shell_lib__load
shell_init_mode
sh_init_mode

test $IS_BASH -eq 1 && {
  # This triggers
  #/etc/profile.d/uc-profile.sh: /usr/share/bashdb/bashdb-main.inc: No such file or directory
  #/etc/profile.d/uc-profile.sh: warning: cannot start debugger; debugging mode disabled
  # at t460s but only sometimes.
  set -o errexit  # set -e
  set -o nounset  # set -u
  set -o pipefail #

  shopt -q extdebug || shopt -s extdebug >&2

  # setting errtrace allows our ERR trap handler to be propagated to functions,
  #  expansions and subshells
  set -o errtrace # same as -E

  # Leave a path of line-numbers in array BASH_LINENO
  # thate tells where functions where called
  set -o functrace # same as -T

  # trap ERR to provide an error handler whenever a command exits nonzero
  #  this is a more verbose version of set -o errexit
  . "$UC_LIB_PATH"/bash-uc.lib.sh
  trap 'bash_uc_errexit' ERR

} || {

  $LOG warn "" "Non-Bash TO-TEST"
}

test $IS_DASH -eq 1 && {
  set -o nounset
}


# Lots of script depend on these basic variables. Validate later.

true "${USER:=$(whoami)}"
true "${username:=$USER}"
true "${hostname:=$(hostname -s)}"

#shellcheck disable=1087
log_key="$username@$hostname:$scriptname[$$]:${1-}"
export log_key UC_LOG_LEVEL

# Pre-set log output level, will re-check and force level later
UC_LOG_LEVEL=${verbosity:=${v:-4}}
export verbosity UC_LOG_LEVEL

# Load and init all lib parts
. "$UC_LIB_PATH"/args-uc.lib.sh
. "$UC_LIB_PATH"/std-uc.lib.sh
. "$UC_LIB_PATH"/str-uc.lib.sh
. "$UC_LIB_PATH"/src-uc.lib.sh
. "$UC_LIB_PATH"/ansi-uc.lib.sh
. "$UC_LIB_PATH"/match-uc.lib.sh
. "$UC_LIB_PATH"/os-uc.lib.sh
. "$UC_LIB_PATH"/date-uc.lib.sh
. "$UC_LIB_PATH"/vc-uc.lib.sh
. "$UC_LIB_PATH"/sys-uc.lib.sh
. "$UC_LIB_PATH"/stdlog-uc.lib.sh
#. "$UC_LIB_PATH"/syslog-uc.lib.sh
. "$UC_LIB_PATH"/conf-uc.lib.sh
. "$UC_LIB_PATH"/uc.lib.sh
for d in copy symlink web line git
do
  . "$UC_LIB_PATH"/uc-d-$d.lib.sh
done
. "$UC_LIB_PATH"/stattab-uc.lib.sh
. "$UC_LIB_PATH"/class-uc.lib.sh
. "$UC_LIB_PATH"/shell-uc.lib.sh

sys_uc_lib__load
std_uc_lib__load
os_uc_lib__load
ansi_uc_lib__load
stdlog_uc_lib__load
#syslog_uc_lib__load
stattab_uc_lib__load
class_uc_lib__load

shell_uc_lib__init
std_uc_lib__init
class_uc_lib__init

case "${TERM-}" in
  ( "" ) ;;
  ( dumb ) ;;
  ( * ) true "${COLORIZE:=1}" ;;
esac

# For log and color output
ansi_uc_lib__init

#
