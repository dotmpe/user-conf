OS-Path-Assert ()
{
  OS-Path-Add "$@" || test 1 -eq $? || return $_
}
