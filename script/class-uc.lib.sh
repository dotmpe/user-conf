# Created: 2020-09-16

class_uc_lib__load ()
{
  ctx_class_types=${ctx_class_types-}${ctx_class_types+" "}Class\ ParameterizedClass
  declare -gA Class__static_type
  declare -gA Class__type
}

class_uc_lib__init ()
{
  test -z "${class_uc_lib_init:-}" || return $_
  : "${_E_nsa:=68}" # std:errors
  : "${ctx_class_types:?} "
  : "${_// /-class }"
  if_ok "$(filter_args lib_uc_islib $_)" || return
  test -z "$_" || {
    lib_require $_ || return
  }
  $LOG info :class.lib:init "Loading static class env"
  class_load_all &&
  class_define_all || return
  $LOG info :class.lib:init "Static class env OK"
  create() { class_init "$@"; }
  destroy() { class_del "$@"; }
}

# The abstract base class with some helpers.
# This keeps the concrete type and constructor params in a global array, the
# instance Id being used as index key.

class_Class__load ()
{
  Class__static_type[Class]=Class
  # Assoc-array to store 'params': arguments passed into Class constructor
  declare -g -A Class__instance=()
}

class_Class_ () # ~ <Instance-Id> .<Message-name> <Args...>
# Methods:
#   .Class <Type> - constructor
#   .__Class - destructor
#
#   .id - Echo Id value for class context
#   .defined - Test wether instance is initialized (constructed)
#   .class - Echo the concrete class name
#   .params - Echo surplus constructor arguments
#
#   .tree - Echo indented info lines for concrete class and all super types
#   .info - Call class.info which prints type, id and constructor params (same as .default and .toString)
{
  case "${call:?}" in

    # 'Constructor' just stores arguments in array. By convention the first
    # word should indicate the concrete type for the Id.
    .__init__ )
        test -n "${1:-}" ||
          $LOG error :Class[$id].__init__ "Concrete type expected" "" 1 || return
        Class__instance[$id]="$*"
        test -z "$super" || $super.__init__ "$@" || return
        ;;

    # 'Destructor'
    .__del__ )
        : "${Class__instance[$id]:?Expected class instance #$id}"
        unset "Class__instance[$id]" ;;

    .id ) echo "$id" ;;
    .defined ) test -n "${Class__instance[$id]:-}" || return ${_E_nsk:?} ;;
    .class )
        : "${Class__instance[$id]:?Expected class instance #$id}"
        test -n "$_" && echo "${_%% *}" || return ${_E_nsk:?} ;;
    .params )
        if_ok "$($self.class)" || return
        : "$(( ${#_} + 1 ))"
        echo "${Class__instance[$id]:$_}" ;;

    .class-tree )
      : "$($self.class)" &&
      name=$_ class_loop class_info | {
        local ind=0
        while read -r line
        do
          printf "%${ind}s"
          echo "$line"
          ind=$(( ind + 3 ))
        done
      } ;;

    .toString | \
    .default | \
    .info ) class_info ;;

    ( * ) return ${_E_next:?} ;;

  esac
  return ${_E_done:?}
}


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

class_ParameterizedClass__load ()
{
  Class__static_type[ParameterizedClass]=ParameterizedClass:Class
  test -z "${ctx_pclass_params:-}" && return
  local p
  for p in $ctx_pclass_params
  do
    declare -g -A "ParameterizedClass__params__${p:?}=()" || return
  done
}

class_ParameterizedClass_ () # ~ <Instance-Id> .<Message-name> <Args...>
# Methods:
#   .__init__ <Type> <Class-params|Params> # constructor
#   XXX:.__del__   # destructor
#
#   .getp <Param-key>                # Get class parameter value
#   .setp <Param-key> <Param-value>  # Set/update class parameter value
#   .param <Key> [<Value>]           # Get/set'er for class parameter field
#   .parkey <Key>                    # Return array name/index for direct access
#
{
  case "${call:?}" in
    ( .__init__ )
      local concrete_type=${1:?}
        shift
        # Handle (initial) constructor args that match *=*, pass rest as argv
        declare -a argv
        while test 0 -lt $#
        do str_globmatch "${1:?}" "*=*" && {
            $self.setp "${1%%=*}" "${1#*=}" || return
          } || argv+=( "$1" )
          shift
        done
        test -z "$super" ||
          $super.__init__ "$concrete_type" "${argv[@]}" || return
      ;;

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

    ( * ) return ${_E_next:?} ;;

  esac
  return ${_E_done:?}
}

# Variant on mparams that takes default value from a static context
class_ParameterizedClass_cparams () # (id,static-ctx) ~ <Class-params-var> <Message> ...
{
  ! str_globmatch " ${!1:?} " "* ${2:?} *" && return ${_E_next:-196}
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

# Helper to map a method call to get/set a parameter directly from/to the array
class_ParameterizedClass_mparams () # (id) ~ <Class-params-var> <Message> ...
{
  ! str_globmatch " ${!1:?} " "* ${2:?} *" && return ${_E_next:-196}
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



class_bases () # ~
{
  local class subclass
  for class in "$@"
  do
    : "Class__static_type[$class]"
    test -n "${!_:-}" || return
    echo "$class"
    if_ok "$(
      for subclass in $_
      do str_wordmatch "$subclass" "$@" ||
        echo "$subclass"
      done)" || return

    class_bases $_ || return
  done
}

# Destructor for previously initialized class instance variables
class_del () # ~ <Var-name>
{
  #if_ok "$(${!1}.instance)" &&
  ${!1}.__del__ &&
  unset $1
}

# Helper for class functions
class_info () # (name,id) ~ # Print human readable Id info for current class context
{
  : "${Class__instance[$id]:?Expected class instance #$id}"
  echo "class.$name:${_// /:}#$id"
}

# Helper for class functions
class_info_tree () # (name,id,super) ~ <Method> # Print tree of Id info of current class and all super-types
{
  class_info
  test -z "${super:-}" ||
    $super$1 | sed 's/^/  /'
}

# The 'new' handler. Initialize a new instance of Type, the lib-init hook
# defines 'create' to defer to this.
class_init () # ~ <Var-name> [<Type>] [<Constructor-Args...>]
{
  local var=${1:?} type=${2:-Class}
  test $# -gt 1 && shift 2 || shift

  # Find new ID for instance
  local new_prefix="class__${type:?} $RANDOM "
  while $new_prefix.defined
  do
    new_prefix="class__$type $RANDOM "
  done

  # Call constructor(s) and store concrete type and optional params for Id
  $new_prefix.__init__ "${type:?}" "$@" &&
    $LOG debug :class-init "Class init returned OK" "$new_prefix.__init__:$*" ||
    $LOG error :class-init "Calling constructor" "E$?:$new_prefix.__init__:$*" $? || return

  # Keep ref key for new class instance at given variable name
  case "$var" in
    local:* ) eval "${var:6}=\"$new_prefix\"" ;;
    * ) declare -g $var="$new_prefix" ;;
  esac
  # NOTE: above global declaration would not work for local vars, and Bash<=5.0
  # cannot tell wether $var already is declared local in an outter function
  # scope. Even more declare or set are/seem useless, so its eval to the rescue.
}

class_define_all ()
{
  local class bases def
  # XXX: unused, but allows class_<Type>_bases callback (iso. class load hook
  # with Class:static-type declaration).
  for class in $ctx_class_types
  do
    def="Class__static_type[$class]"
    test -n "${!def-}" || {
      ! sh_fun class_${class}__bases && bases=$class:Class || {
        bases=$($_) || return
      }
      declare -g "$def=$bases" || return
    }
  done

  #
  for class in "${!Class__static_type[@]}"
  do
    : "$(class_static_mro "$class")" || return
    declare -g Class__type[$class]=$class${_:+:}${_//$'\n'/:}
  done

  for class in $ctx_class_types
  do
    : "
class__$class () {
  local name=$class id=\${1:?} call=\${2:-_repr}
  test 1 -lt \$# && shift 2 || shift
  local self=\"\${self:-class__$class \$id }\"

  class_run \"\$call\" \"\$@\"
}"
    eval "$_"
  done
}

# Run load handler for every class to declare global vars of each
class_load ()
{
  for class in $ctx_class_types
  do
    # If class corresponds to lib or other group, require that to be initialized
    {
      lib_uc_islib "${class,,}-class" ||
      lib_uc_islib "ctx-${class,,}" ||
      lib_uc_islib "${class,,}"
    } && {
      test "ctx-class" = "$_" || {
        lib_require "$_" && lib_init "$_" ||
          $LOG alert :class-load "Failed loading class context" "E$?:$class:$_" $? ||
          return
      }
    }
    # Perform if needed or continue
    sh_fun class_${class}__load || continue
    $_ ||
      $LOG error :class-load "During class load" "E$?:$class" $? || return
  done
}

# 1. call Class-load hooks (declare Class:static-type)
# 2. load missing baseclasses (amend ctx-class-types)
# 3. repeat until all done (every class-type is found in both)
# XXX: called from lib init hook, so need to deal with recursive lib-init
class_load_all ()
{
  local class type missing
  for class in $ctx_class_types
  do
    sh_fun class_${class}__load || continue
    "$_" ||
      $LOG error :class-load-all "During class load" "E$?:$class" $? || return
  done
  for class in "${!Class__static_type[@]}"
  do
    for type in ${Class__static_type[$class]//:/ }
    do
      : "Class__static_type[$type]"
      test -n "${!_-}" || missing=${missing-}${missing:+ }${type,,}-class
    done
  done
  test -z "${missing-}" || lib_require $missing
}

class_loop () # (name,id) ~ <Item-handler> <Args...>
{
  local type super step=0
  if_ok "$(class_resolve "$name")" || return
  while read -r name type
  do
    self="class__${name} $id " \
    super="${type:+class__${type} $id }" \
    "${1:?}" "${@:2}" || {
      test ${_E_done:?} -eq $? && return
      test ${_E_next:?} -eq $_ && continue
      return $_
    }
  done <<< "$_"
  test 0 -ne $step || return ${_E_nsa:?}
}

# rc: resolution-chain
class_run () # (name,id) ~ <Call> <Args...>
{
  class_loop class_run_call "$@"
}

class_run_call () # (name,id,self,super) ~ <Call> <Args...>
{
  call="${1:?}" \
  class_${name}_ "${@:2}" && step=$(( step + 1 ))
}

class_resolve ()
{
  local i n class
  rc=( ${Class__type[$name]//:/ } )
  n=$(( ${#rc[@]} - 1 ))
  for i in "${!rc[@]}"
  do
    class=${rc[i]}
    sh_fun class_${class}_ || continue
    test $n -gt $i && super="${rc[$(( i + 1 ))]}" || super=
    echo $class $super
  done
}

foooo ()
{
  local i n class super step=0
  rc=( ${Class__type[$name]//:/ } )
  n=$(( ${#rc[@]} - 1 ))
  for i in "${!rc[@]}"
  do
    class=${rc[i]}
    sh_fun class_${class}_ || continue
    test $n -gt $i && super="class_${rc[$(( i + 1 ))]}_ " || super=
    call=${1:?} class_${class}_ "${@:2}" && step=$(( step + 1 )) || {
      test ${_E_done:?} -eq $? && return
      test ${_E_next:?} -eq $_ && continue
      return $_
    }
  done
  test 0 -ne $step || return ${_E_nsa:?}
}

class_static_mro ()
{
  local type
  set -- ${Class__static_type[${1:?}]//:/ }
  shift
  while test 0 -lt $#
  do
    type="$1"
    echo "$1"
    shift
    test -z "${Class__static_type[$type]-}" || {
      set -- ${_//:/ } "$@"
      shift
    }
  done
}

#
