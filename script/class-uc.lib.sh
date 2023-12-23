# Created: 2020-09-16

class_uc_lib__load ()
{
  ctx_class_types=${ctx_class_types-}${ctx_class_types+" "}Class\ ParameterizedClass
  declare -gA Class__static_calls
  declare -gA Class__static_type
  declare -gA Class__type
}

class_uc_lib__init ()
{
  test -z "${class_uc_lib_init:-}" || return $_
  : "${_E_fail:=1}" # std:errors
  : "${_E_error:=2}" # std:errors
  : "${_E_nsk:=67}" # std:errors
  : "${_E_nsa:=68}" # std:errors
  : "${_E_next:=196}" # std:errors
  : "${_E_done:=200}" # std:errors
  : "${ctx_class_types:?} "
  : "${_// /-class }"
  if_ok "$(filter_args lib_uc_islib $_)" || return
  test -z "$_" || {
    lib_require $_ || return
  }
  $LOG info :class.lib:init "Loading static class env"
  class_load_all &&
  class_define_all || return
  $LOG debug :class.lib:init "Static class env OK"
  create() { class_init "$@"; }
  destroy() { class_del "$@"; }
}


# The abstract base class with some helpers.
# This keeps the concrete type and constructor params in a global array, the
# instance Id being used as index key.

class_Class__load ()
{
  Class__static_type[Class]=Class
  #Class__static_calls[Class]=exists,hasattr
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
        Class__instance[$id]="$*"
        class_super_optional_call "$@"
      ;;

    # 'Destructor'
    .__del__ )
        unset "Class__instance[$id]" ;;

    .attr ) # ~ <Key> [<Class>] [<Default>]  # Get field value from class instance value
        : "${1//:/__}"
        : "${2:-Class}__${_//-/_}[${id:?}]"
        ! "${stb_atr_req:-false}" "$_" && {
          "${stb_atr_strnz:-false}" "$_" && {
            : "${!_:-${3:-}}"
          } || {
            : "${!_-${3:-}}"
          }
        } || {
          : "${!_}"
        }
        echo "$_"
        #test - != "$_" &&
        #  echo "$_" || {
        #    $LOG warn :"$self" "No such attribute" "${2-}:$1" ${_E_nsk:?} || return
        #  }
      ;;
    .defined ) test "(unset)" != "${Class__instance[$id]-"(unset)"}" ||
      return ${_E_nsk:?} ;;
    .class ) echo "${SELF_NAME:?}" ;;
    .class-resolve ) class_resolve "$SELF_NAME" ;;
    .class-tree )
      class_loop class_info | {
        local ind=0
        while read -r line
        do
          printf "%${ind}s"
          echo "$line"
          ind=$(( ind + 3 ))
        done
      }
    ;;
    .cparams|.class-params ) echo "${Class__instance[$id]}" ;;
    .id ) echo "$id" ;;
    .query-class ) class_query "$@" ;;
    .switch-class ) class_switch "$@" ;;
    .set-attr )
        test $# -ge 2 -a $# -le 3 || return ${_E_MA:?}
        : "${1:?}"
        : "${1//:/__}"
        : "${3:-Class}__${_//-/_}[${id:?}]"
        declare -g "$_"="$2"
        $LOG debug : "Updated attribute" "E$?:$_" $?
      ;;
    .toString | \
    .default | \
    .info ) class_info ;;

    ( * ) return ${_E_next:?} ;;

  esac && return ${_E_done:?}
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
        # Handle (initial) constructor args that match *=*, pass rest as argv
        declare -a argv
        while test 0 -lt $#
        do str_globmatch "${1:?}" "*=*" && {
            $self.setp "${1%%=*}" "${1#*=}" ||
              $LOG error :pclass:init "Set constructor property" "E$?:$1" $? ||
              return
          } || argv+=( "$1" )
          shift
        done
        class_super_optional_call "$@"
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

  esac && return ${_E_done:?}
}

# Variant on mparams that takes default value from a static context
class_ParameterizedClass_cparams () # (id,static-ctx) ~ <Class-params-var> <Message> ...
{
  ! str_globmatch " ${!1:?} " "* ${2:?} *" && return ${_E_next:-196}
  test 3 -ge $# || return ${_E_GAE:-193}
  local parkey="ParameterizedClass__params__${2:?}[$SELF_ID]"
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
  local parkey="ParameterizedClass__params__${2:?}[$SELF_ID]"
  test 3 -eq $# && {
    declare -g "$parkey=$3" || return
  } || {
    "${parkey_exists:-true}" &&
      echo "${!parkey:?Missing param field $2 on instance #$SELF_ID}" ||
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

class_define_all ()
{
  test 0 -lt $# || set -- ${ctx_class_types:?}

  test -z "${CTX_CLASS:-}" ||
    set --  $(for class in "$@"; do
        str_wordmatch "$class" $CTX_CLASS || echo "$class"
      done)

  local class bases def
  # XXX: unused, but allows class_<Type>_bases callback (iso. class load hook
  # with Class:static-type declaration).
  for class in "$@"
  do
    def="Class__static_type[$class]"
    test -n "${!def-}" || {
      ! sh_fun class_${class}__bases && bases=$class:Class || {
        bases=$($_) || return
      }
      declare -g "$def=$bases" || return
    }
  done

  for class in "$@"
  do
    : "Class__type[$class]"
    test -n "${!_:-}" || {
      if_ok "$(class_static_mro "$class" | tac | remove_dupes | tac )" || return
      declare -g "Class__type[$class]=$class${_:+:}${_//$'\n'/:}"
    }
  done

  for class in "$@"
  do
    sh_fun class.$class || {
      : "
class.$class () {
  test $class = \"\${1:?}\" && {
    local SELF_NAME=$class SELF_ID=\${2:?} call=\${3:-.toString} self id \
      CLASS_{IDX,TYPERES,TYPEC}
    id=\$SELF_ID
    self=\"class.$class $class \$id \"

    test 2 -lt \$# && shift 3 || shift 2

    class_loop class_run_call \"\$@\"
    return

  } || {

    CLASS_IDX=\$(( CLASS_IDX + 1 ))
    test $class = \"\${CLASS_TYPERES[\$CLASS_IDX]}\" || {
      $LOG alert : Mismatch \"\$CLASS_IDX:$class!=\$_:\$*\"
      return 1
    }
    CLASS_NAME=$class
    CLASS_TYPEC=\$(( CLASS_TYPEC - 1 ))
    test \$CLASS_TYPEC -gt 0 && {
      SUPER_NAME=\${CLASS_TYPERES[\$(( CLASS_IDX + 1 ))]}
      super=\"class.\${SUPER_NAME:?} \${SELF_NAME:?} \"
    } || SUPER_NAME= super=

    local call=\${2:-.toString}
    shift 2
    class_${class}_ \"\$@\"
  }
}
"
      eval "$_"
    }
  done

  CTX_CLASS=${CTX_CLASS:-}${CTX_CLASS:+ }"$*"
}

# Destructor for previously initialized class instance variables
class_del () # ~ <Var-name>
{
  #if_ok "$(${!1}.instance)" &&
  ${!1}.__del__ &&
  unset $1
}

class_exists () # ~ <Class>
{
  test -n "${Class__static_type[${1:?}]:-}"
}

# Helper for class functions
class_instance () # (name,id) ~ # Print human readable Id info for current class context
{
  #: "${Class__instance[$id]:?Expected class instance #$id}"
  echo "class.$SELF_NAME $SELF_ID"
}

class_info ()
{
  echo "class.$CLASS_NAME $SELF_ID"
}

# The 'new' handler. Initialize a new instance of Type, the lib-init hook
# defines 'create' to defer to this.
class_init () # ~ <Var-name> [<Type>] [<Constructor-Args...>]
{
  local var=${1:?} type=${2:-Class}
  test $# -gt 1 && shift 2 || shift

  # Find new ID for instance
  local new_prefix="class.${type:?} $type $RANDOM "
  while $new_prefix.defined
  do
    new_prefix="class.$type $type $RANDOM "
  done

  # Call constructor(s) and store concrete type and optional params for Id
  $new_prefix.__init__ "${type:?}" "$@" &&
    $LOG debug :class-init "Complete" "$new_prefix.__init__:$*" ||
    $LOG error :class-init "Running constructors" "E$?:$new_prefix.__init__:$*" $? || return

  # Keep ref key for new class instance at given variable name
  case "$var" in
    local:* ) eval "${var:6}=\"$new_prefix\"" ;;
    * ) declare -g $var="$new_prefix" ;;
  esac
  # NOTE: above global declaration would not work for local vars, and Bash<=5.0
  # cannot tell wether $var already is declared local in an outter function
  # scope. Even more declare or set are/seem useless, so its eval to the rescue.
}

# Run load handler for every class to declare global vars of each
class_load ()
{
  test 0 -lt $# || set -- ${ctx_class_types:?}
  local class
  for class in "$@"
  do
    test "class-uc" = "$_" ||
      class_exists "$class" && continue
    # If class corresponds to lib or other group, require that to be initialized
    lib_uc_islib "${class,,}-class" && {
      lib_require "$_" && lib_init "$_" ||
        $LOG alert :class-load "Failed loading class context" "E$?:$class:$_" $? ||
          return
    } || return 127
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
  test 0 -lt $# || set -- ${ctx_class_types:?}
  local class type missing
  for class in "$@"
  do
    class_exists "$class" && continue
    # Initialize classes already loaded or loaded without using class-load.
    sh_fun class_${class}__load || continue
    $_ ||
      $LOG error :class-load-all "During class load" "E$?:$class" $? || return
  done
  for class in "$@"
  do
    class_exists "$class" ||
      $LOG error : "No such class" "E$?:$class" $? || return
    : "Class__static_type[$class]"
    for type in ${!_//:/ }
    do
      : "Class__static_type[$type]"
      test -n "${!_-}" || missing=${missing-}${missing:+ }${type,,}-class
    done
  done
  test -z "${missing-}" || lib_require $missing
}

class_loop () # (SELF-{NAME,ID}) ~ <Item-handler> <Args...>
{
  declare name type super
  declare -a CLASS_TYPERES

  if_ok "$(class_resolve "$SELF_NAME")" &&
  while read -r name type
  do
    CLASS_TYPERES+=( "$name" )
  done <<< "$_" || return

  for (( CLASS_TYPEC=${#CLASS_TYPERES[@]}, CLASS_TYPEC--, CLASS_IDX=0;
    CLASS_TYPEC >= 0;
    CLASS_IDX++, CLASS_TYPEC-- ))
  do
    CLASS_NAME=${CLASS_TYPERES[$CLASS_IDX]:?}
    test $CLASS_TYPEC -gt 0 && {
      SUPER_NAME=${CLASS_TYPERES[$(( CLASS_IDX + 1 ))]}
      super="class.${SUPER_NAME:?} ${SELF_NAME:?} "
    } || SUPER_NAME= super=

    "${1:?}" "${@:2}" || {
      test ${_E_done:?} -eq $? && return
      test ${_E_next:?} -eq $_ && continue
      return $_
    }
  done
}

# Return zero status when Type matches Class:instance[id], and else update
# setting and return E:done status.
class_query () # (id) ~ <Type>
{
  local type=${Class__instance[$id]}
  test "${1:?}" = "$type" || {
    test -n "${Class__type[$1]-}" &&
    stderr echo $type=${Class__type[$1]} &&
    $LOG info "" "Changing class" "$id:$type->$1" &&
    type=$1 &&
    declare -g "Class__instance[$id]=$type" &&
    return ${_E_done:?}
  } ||
    $LOG alert "" "Query failed" "id=$id:type=$1:E$?" $?
}

class_resolve () # ~ <name>
{
  typeset i n class
  typeset -a rc
  rc=( ${Class__type[${1:?}]//:/ } )
  n=$(( ${#rc[@]} - 1 ))
  for i in "${!rc[@]}"
  do
    class=${rc[i]}
    sh_fun class_${class}_ || continue
    test $n -gt $i && super="${rc[$(( i + 1 ))]}" || super=
    echo $class $super
  done
}

class_run_call ()
{
  class_${CLASS_NAME:?}_ "$@"
}

class_static_mro () # ~ <name>
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

class_super_optional_call () # (id,self,super,call) ~ <Args...>
{
  test -z "$super" || $super$call "$@" || {
    local r=$? lk=":${CLASS_NAME:?}$call:$SELF_ID"
    test ${_E_done:?} -eq $r && {
      $LOG debug "$lk" "Superclass call done" \
          "E$r:${SELF_NAME:?}::${CLASS_TYPERES[*]}"
          #"E$r:${SELF_NAME:?}"
      return
    }
    test ${_E_next:?} -eq $r && {
      $LOG info "$lk" "Superclass call unhandled" \
          "E$r:super=${SUPER_NAME:-}:concrete=${SELF_NAME:?}:$#:$*"
      return $r
    }
    $LOG error "$lk" "Superclass call failure" \
          "E$r:super=${SUPER_NAME:-}:concrete=${SELF_NAME:?}:$#:$*" $r
  }
}

# Refresh reference to current class (after Class:instance was changed) or reset
# to given type.
class_switch () # (id) ~ <Var-name> [<Type>]
{
  local var=${1:?} type
  case "$var" in
    local:* ) var="${var:6}" ;
  esac
  test -z "${2-}" ||
    class_query "$2" ||
    test ${_E_done:?} -eq $? || return $_
  type=${Class__instance[$id]}
  : "class.${type:?} $type $id "
  test "${!var}" = "$_" && return
  case "$1" in
    local:* ) eval "$var=\"$_\"" ;;
    * ) declare -g $var="$_"
  esac
  $LOG info "" "Class reference updated" "$_"
}

#
