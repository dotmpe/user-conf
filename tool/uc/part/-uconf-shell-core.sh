#
# /usr/share/uc/-uconf-shell-core.sh
: "${UC_SYSLOG_LEVEL:=4}"
: "${uc_stat:=return}"
export UC_SYSLOG_LEVEL=$UC_SYSLOG_LEVEL uc_stat=$uc_stat

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
