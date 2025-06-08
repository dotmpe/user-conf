#
: "${UC_SYSLOG_LEVEL:=4}"
: "${uc_stat:=return}"
export UC_SYSLOG_LEVEL=$UC_SYSLOG_LEVEL uc_stat=$uc_stat

# TODO: integrate with existing parts
declare +x v UC_SHELL_DEBUG UC_DEBUG DEBUG VERBOSE QUIET
#export UC_SH_ALIASES=false
#export QUIET=false
#export VERBOSE=true
#export UC_SHELL_DEBUG=true
#export UC_DEBUG=true
#export DBUS_DEBUG=false
#export DEBUG=true

fnmatch ()
{
  : group "-uconf-shell-log.sh"
  : copy "str.lib.sh"
  case "$2" in ${1} ) return 0 ;; *) return 1 ;; esac
}

is_fun ()
{
  #: "${1:?${ENV_CTX}:Is_Fun: Symbol name expected}"
  >/dev/null typeset -F "${1}"
}

# uconf-shell-log always loads completely on source, but does
# load-once-then-refresh handling too
. /srv/conf-local/tool/uconf/part/-uconf-shell-log.sh

# Id: /usr/share/uc/-uconf-shell-core.sh                            ex:ft=bash:
