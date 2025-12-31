Sh-Fun-Body ()
{
: param "~ <Ref-fun> ..."
: input "${1:?$FUNCNAME: Function name expected}"
  :pass "$(typeset -f "${1}")" || return
  : "${_#* () }"
  : "${_:4:-2}"
  echo "$_"
}
