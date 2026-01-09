uconf_extra_pre=User-Conf.Extra
uconf_extra_fun=(
  TODO
)

TODO () {
  local ctx=${ENV_CTX-}
  # XXX: print paramter + ENV_CTX, default parameter standard + bash source
  [[ ${*:+set} ]] &&
  ctx=${ctx-${BASH_SOURCE[1]}} || {
    : "${*:-$(caller 0)}"
    set -- "no description (at ${_##* }:${_%% *})"
  }
  # XXX: could also or alt use funcname in certain situations
  #_IFDBG _WARN "To-Do: ${*:-${FUNCNAME[1]}}"
  >&2 echo "TODO: ${*}${ctx:+, ${ctx}}"
  return ${_E_todo:-${_E_missing:-125}}
}
