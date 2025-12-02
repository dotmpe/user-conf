uconf_directives_core_pre=User-Conf.Directives
uconf_directives_core_fun=(
  .apply-env
  .apply-path
  .apply-profiles
  .copy-or-symlink
  .install-packages
)

declare -gA \
uconf_directives_core_als=(
  [uconf_apply]=.apply-profiles
)

User-Conf.Directives.apply-path ()
{
  User-Script.OS.lookup-append "${@}" SCRIPTPATH
}

User-Conf.Directives.copy-or-symlink ()
{
  TODO "$FUNCNAME"
}

User-Conf.Directives.apply-env ()
{
  TODO "$FUNCNAME"
}

User-Conf.Directives.apply-profiles ()
{
  TODO "$FUNCNAME"
}

#
