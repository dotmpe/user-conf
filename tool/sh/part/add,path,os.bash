OS-Path-Add ()
{
  : about "Simple PATH helper to append only new, unique instance"
  : param "<Directory> [<Var=PATH>] ..."
  : extended "Using this helps keeping PATH cleaner, but it doesnt behave \
      like path_append but returns false (1) if already found"
  : notes TODO "Really should write sys-wordv-add or something"
  : notes XXX "This does not export PATH"
  : notes : "Exactly the same implementation as shipped with Debian/Ubuntu"
  local -n _PATH=${2:-PATH}
  : input "${_PATH?Path variable expected, $ENV_CTX:$FUNCNAME}"
  : input "${1:?Path value expected, $ENV_CTX:$FUNCNAME}"
  case ":${_PATH}:" in
  ( *:"${1}":*) false
    ;;
  ( * )
      _PATH="${_PATH:+${_PATH}:}${1}"
  esac
}
