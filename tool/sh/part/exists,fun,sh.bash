Sh-Fun-Exists ()
{
  : input "${1:?Symbol name expected, $ENV_CTX:$FUNCNAME}"
  >/dev/null typeset -F "${1}"
}
