uconf_core_lib_pre=User-Conf.Directive
uconf_core_lib_fun=(
  .apply-env
  .apply-path
  .apply-profiles
  .copy-or-symlink
  .install-packages
)

declare -gA \
uconf_core_lib_als=(
  [uconf_apply]=.apply-profiles
)

User-Conf.Directive.apply-path ()
{
  User-Script.OS.lookup-append "${@}" SCRIPTPATH
}

User-Conf.Directive.copy-or-symlink ()
{
  TODO "$FUNCNAME"
}

User-Conf.Directive.apply-env ()
{
  TODO "$FUNCNAME"
}

User-Conf.Directive.apply-profiles ()
{
  : "${*}"
  require ${_// /.u-c.bash }.u-c.bash || return
  local fun
  for fun
  do "$fun" || return
  done
}

#
