# Allow for more convenient parameterization of class contexts on construction.
# Normally 'params' are kept as words in Class__instances[ID] which are a bit
# messy to access.
#
# TODO: map each additional param value to flags, ie. flags='abc' maps first
# three params to a, b and c flag keys resp.
#
# Additional constructor arguments that are formatted '*=*' are interpreted
# as assignments for params. NOTE: every class that uses particular params
# should add them to ctx-plass-params before ctx-class.lib is initialized, so
# they have their storage arrays created for them on class.load. Also, as pclass
# does not track which params belong to which concrete class, so it should not
# map methods to params, but implementing classes can do so using
# class.ParameterizedClass.mparams.


ctx_pclass_lib__load ()
{
  lib_require str ctx-class || return
  # str:fnmatch
  ctx_class_types=${ctx_class_types-}${ctx_class_types+" "}ParameterizedClass
}


class.ParameterizedClass () # ~ <Instance-Id> .<Message-name> <Args...>
# Methods:
#   .ParameterizedClass <Type> <Class-params|Params> # constructor
#   .__ParameterizedClass                            # destructor
#
#   .getp <Param-key>                # Get class parameter value
#   .setp <Param-key> <Param-value>  # Set/update class parameter value
#   .param <Key> [<Value>]           # Get/set'er for class parameter field
#   .parkey <Key>                    # Return array name/index for direct access
#
#   .class-tree                      # see class.tree
#   .class-info                      # see class.info
{
  test $# -gt 0 || return 177
  test $# -gt 1 || set -- "$1" .default
  local name=ParameterizedClass super_type=Class self super id=${1:?} m=$2
  self="class.$name $1 "
  super="class.$super_type $1 "
  shift 2

  case "$m" in
    ( ".$name" ) local class_type=${1:?}
        shift
        declare -a argv
        while test 0 -lt $#
        do fnmatch "*=*" "${1:?}" && {
            $self.setp "${1%%=*}" "${1#*=}" || return
          } || argv+=( "$1" )
          shift
        done
        $super.$super_type "$class_type" "${argv[@]}"
      ;;
    ( ".__$name" ) $super.__$super_type ;;

    # Get/set'er access for ParameterizedClass params.
    ( .setp )
        declare -g "ParameterizedClass__params__${1:?}[$id]=$2"
      ;;
    ( .getp )
        : "ParameterizedClass__params__${1:?}[$id]"
        "${parkey_exists:-true}" "$_" && echo "${!_}" || echo "${!_:-}"
      ;;
    ( .param ) test 2 -ge $# || return ${_E_GAE:-193}
        test 2 -eq $# && {
          $self.setp "$@" || return
        } ||
          $self.getp "$@" ;;
    ( .parkey )
        echo "ParameterizedClass__params__${1:?}[$id]"
      ;;

    ( .class-tree | .class-context ) class.info-tree .tree ;;
    ( .class-info | .toString | .default ) class.info ;;

    ( * ) $super"$m" "$@" ;;
  esac
}

# Variant on mparams that takes default value from a static context
class.ParameterizedClass.cparams () # (id,static-ctx) ~ <Class-params-var> <Message> ...
{
  ! fnmatch "* ${2:?} *" " ${!1:?} " && return ${_E_next:-196}
  test 3 -ge $# || return ${_E_GAE:-193}
  local parkey="ParameterizedClass__params__${2:?}[$id]"
  test 3 -eq $# && {
    declare -g "$parkey=$3" || return
  } || {
    : "${!parkey-unset}"
    test unset = "$_" && {
      $static_ctx$2 "${@:3}" || return
    } || echo "$_"
  }
}

class.ParameterizedClass.load ()
{
  test -z "${ctx_pclass_params:-}" && return
  local p
  for p in $ctx_pclass_params
  do
    declare -g -A "ParameterizedClass__params__${p:?}=()" || return
  done
}

# Helper to map a method call to get/set a parameter directly from/to the array
class.ParameterizedClass.mparams () # (id) ~ <Class-params-var> <Message> ...
{
  ! fnmatch "* ${2:?} *" " ${!1:?} " && return ${_E_next:-196}
  test 3 -ge $# || return ${_E_GAE:-193}
  local parkey="ParameterizedClass__params__${2:?}[$id]"
  test 3 -eq $# && {
    declare -g "$parkey=$3" || return
  } || {
    "${parkey_exists:-true}" &&
      echo "${!parkey:?Missing param field $2 on instance #$id}" ||
      echo "${!parkey:-}"
  }
}


