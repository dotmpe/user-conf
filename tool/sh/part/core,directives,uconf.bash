uconf_directives_core_pre=User-Conf.Directives
uconf_directives_core_fun=(
  .path
  .copy-or-symlink
  -env
  .apply-profile
)
declare -gA \
uconf_directives_core_als=(
  [uconf_apply]=.apply-profiles
)

User-Conf.Directive.path ()
{
  User-Script.OS.lookup-append "${@}" SCRIPTPATH
}

User-Conf.Directive.copy-or-symlink ()
{
  TODO "$FUNCNAME"
}

User-Conf.Directive.env ()
{
  TODO "$FUNCNAME"
}

User-Conf.Directive.apply ()
{
  TODO "$FUNCNAME"
}

#
