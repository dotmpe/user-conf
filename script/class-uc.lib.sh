# Created: 2020-09-16

## Foundation for class-like behavior and data instances of composite types

#  Class-like behavior for Bash uses global arrays and random, numerical Ids to
#  store types and other attributes of new 'objects', and class_<Class-name>_
#  handler functions to define methods (or other calls) to be performed on
#  such objects.

class_uc_lib__load ()
{
  lib_require os sys lib-uc std-uc || return
  class_uc_cch='_.-+='
  class_uc_cchre='_\.\-\+\*\!&\$\^%#='
  ctx_class_types=${ctx_class_types-}${ctx_class_types+" "}Class\ ParameterizedClass
  typeset -gA Class__static_calls
  typeset -gA Class__static_type
  typeset -gA Class__type
  typeset -gA Class__libs
}

class_uc_lib__init ()
{
  test -z "${class_uc_lib_init:-}" || return $_
  create () { class_new "$@"; }
  destroy () { class_del "$@"; }
}


# The abstract base class with some helpers.

class_Class__load ()
{
  Class__static_type[Class]=Class
  #Class__static_calls[Class]=exists,hasattr
  # Assoc-array to store 'params': arguments passed into Class constructor
  typeset -g -A Class__instance=()
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

    .attr ) # ~ <Key> [<Class-name>] [<Default>]  # Get field value from class instance value
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
    .class-attributes ) class_loop class_attributes ;;
    .class-calls ) class_loop class_calls ;;
    .class-debug )
        $self.class-tree &&
        $self.class-attributes &&
        $self.class-calls
      ;;
    .class-methods ) class_loop class_methods ;;
    .class-resolve ) class_resolve "${SELF_NAME:?}" ;;
    .class-tree )
        class_loop class_info | {
          # XXX: turns it into a single indented branch
          typeset ind=0
          while read -r line
          do
            printf "%${ind}s"
            echo "$line"
            ind=$(( ind + 3 ))
          done
        }
      ;;
    .class-typeset ) class_loop class_typeset ;;
    .cparams|.class-params ) echo "${Class__instance[$id]}" ;;
    .id ) echo "$id" ;;
    .query-class ) class_query "$@" ;;
    .switch-class ) class_switch "$@" ;;
    .set-attr )
        test $# -ge 2 -a $# -le 3 || return ${_E_MA:?}
        : "${1:?}"
        : "${1//:/__}"
        : "${3:-Class}__${_//-/_}[${id:?}]"
        typeset -g "$_"="$2"
        $LOG debug : "Updated attribute" "E$?:$_" $?
      ;;
    .toString | \
    .default | \
    .info ) class_info ;;

    * ) return ${_E_next:?}

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
  test -z "${ctx_pclass_params-}" && return
  typeset p
  for p in $ctx_pclass_params
  do
    typeset -g -A "ParameterizedClass__params__${p:?}=()" || return
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
        typeset -a argv
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
        typeset -g "ParameterizedClass__params__${1:?}[$id]=$2"
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
  typeset parkey="ParameterizedClass__params__${2:?}[$OBJ_ID]"
  test 3 -eq $# && {
    typeset -g "$parkey=$3" || return
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
  typeset parkey="ParameterizedClass__params__${2:?}[$OBJ_ID]"
  test 3 -eq $# && {
    typeset -g "$parkey=$3" || return
  } || {
    "${parkey_exists:-true}" &&
      echo "${!parkey:?Missing param field $2 on instance #$OBJ_ID}" ||
      echo "${!parkey:-}"
  }
}


# Helper for class-attributes that lists all variables for current class
# context.
class_attributes () # (self) ~
{
  : ${CLASS_NAME:?}__
  typeset attr attrs=() c=${#_}
  if_ok "$(compgen -A variable ${CLASS_NAME:?}__)" || return 0
  <<< "$_" mapfile -t attrs &&
  for attr in "${attrs[@]}"
  do
    echo "$CLASS_NAME ${attr:$c}"
  done
}

# XXX: unused, cleanup
class_bases () # ~ <Class-names...>
{
  typeset class subclass
  for class in "${@:?class-bases: Class names expected}"
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

# Helper for class-loop that lists all accepted calls for current class context.
# See also class-methods and class-attributes.
class_calls () # (name) ~
{
  typeset call calls=() re
  re=${class_cre:-"^ *\K[A-Za-z0-9\|\ $class_uc_cchre]*(?=\)$)"}
  if_ok "$(typeset -f class_${CLASS_NAME:?}_ | grep -Po "$re")" &&
  test -n "$_" || return ${_E_next:?}
  <<< "$_" mapfile -t calls &&
  for call in "${calls[@]}"
  do
    echo "$CLASS_NAME $call"
  done
}

class_compile_mro () # ~ <Class-name>
{
  : "Class__type[${1:?class-compile-mro: Class name expected}]"
  test -n "${!_:-}" || {
    if_ok "$(class_static_mro "${1:?}" | tac | remove_dupes | tac )" || return
    typeset -g "Class__type[${1:?}]=${1:?}${_:+:}${_//$'\n'/:}"
  }
}

class_define () # ~ <Class-name> # Generate function to call 'class methods'
{
  declare class=${1:?class-define: Class name expected}
  : "
class.$class () {
  test $class = \"\${1:?}\" && {
    # Start new call resolution.

    typeset SELF_NAME=$class OBJ_ID=\${2:?} call=\${3:-.toString} self id \
      CLASS_{IDX,TYPERES,TYPEC}
    id=\$OBJ_ID
    self=\"class.$class $class \$id \"

    test 2 -lt \$# && shift 3 || shift 2

    class_loop class_run_call \"\$@\"
    return

  } || {
    # Make call to this class' methods for other types

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

    typeset call=\${2:-.toString}
    shift 2
    class_${class}_ \"\$@\"
  }
}
"
  eval "$_"
}

class_define_all () # ~ <Class-names...>
{
  test 0 -lt $# || set -- ${ctx_class_types:?}
  : "${@:?class-define-all: Class names expected}"

  # Skip if already defined
  set -- $(filter_args "not class_defined" "$@")
  test 0 -eq $# && return

  typeset class bases def
  # XXX: unused, but allows class_<Type>_bases callback (iso. class load hook
  # with Class:static-type declaration).
  for class in "$@"
  do
    def="Class__static_type[$class]"
    test -n "${!def-}" || {
      ! sh_fun class_${class}__bases && bases=$class:Class || {
        bases=$($_) || return
      }
      typeset -g "$def=$bases" || return
    }
  done

  for class in "$@"
  do
    class_compile_mro "$class" || return
  done

  for class in "$@"
  do
    sh_fun class.$class || class_define "$class" || return
  done
}

class_defined () # ~ <Name>
{
  : "${1:?class-defined: Class name expected}"
  sh_fun class.$_
}

# Destructor for previously initialized class instance variables
class_del () # ~ <Var-name>
{
  : "${1:?class-del: Variable name expected}"
  #if_ok "$(${!1}.instance)" &&
  ${!_:?class-del: Instance reference expected}.__del__ &&
  unset $1
}

class_exists () # ~ <Class-name>
{
  test -n "${Class__static_type[${1:?class-exists: Class name expected}]:-}"
}

# Helper for class functions
class_info () # (name,id) ~ # Print human readable Id info for current class context
{
  #: "${Class__instance[$id]:?Expected class instance #$id}"
  echo "class.${CLASS_NAME:?} ${OBJ_ID:?}"
}

#    Prepare everything for given classes to create new instances using
#    class-new. This includes:
#      - class-load
#      - class-define-all, for given classes and all base types
class_init () # ~ <Class-names...>
{
  $LOG info :class.lib:init "Loading static class env" "$#:$*"
  class_load "${@:?class-init: Class names expected}" &&
  declare -a bases &&
  if_ok "$(for class in "$@"
    do class_static_mro "$class" || return
    done | awk '!a[$0]++')" &&
  <<< "$_" mapfile -t bases &&
  class_define_all "$@" "${bases[@]}" &&
  $LOG debug :class.lib:init "Prepared class env OK" "$#:$*"
}

# Load classes (source scripts and run load hooks) and prerequisite libs.
class_load () # ~ [<Class-names...>]
{
  test 0 -lt $# || set -- ${ctx_class_types:?}
  typeset lk=${lk:-:}${lk:+:}uc:class-load
  typeset class

  # Source scripts and run class 'load' hooks
  for class in "${@:?$lk: Class names expected}"
  do
    class_loaded "$class" ||
    class_load_def "$class" ||
      $LOG alert "$lk" "Finding definitions" "E$?:$class" $? || return
    class_exists "$class" || {
      sh_fun class_${class}__load ||
        $LOG alert "$lk" "Expected class 'load' hook" "$class" 1 || return
      $_ ||
        $LOG error "$lk" "During class load" "E$?:$class" $? || return

      $LOG debug "$lk" "Done loading" "$class"
    }
  done

  # Load prerequisite libs
  class_load_libs "$@" || return

  # Recurse for base classes
  typeset -a bases
  <<< "${Class__static_type[${1:?}]//:/$'\n'}" mapfile -t bases &&
  unset "bases[0]" && {
    test 0 -eq ${#bases[@]} || class_load "${bases[@]}"
  }
}

#    Try to find sh lib or class.sh file and source that (uses lib-uc.lib).
class_load_def () # ~ <Class-name>
{
  : "${1:?class-load-def: Class name expected}"
  # XXX: old method of loading?
  # If class corresponds to lib or other group, require that to be initialized
  lib_uc_islib "${1,,}-class" && {
    lib_require "$_" && lib_init "$_" ||
      $LOG alert :uc:class:load-def "Failed loading class context" \
        "E$?:${1:?}:$_" $? || return
  } || {
    # New method: from .class.sh files
    # (with two optional load hooks, but no init hook)
    lib_uc_kin=_class lib_uc_ext=.class.sh \
      lib_uc_islib "${class,,}" || return 127
    lib_uc_kin=_class lib_uc_ext=.class.sh \
      lib_require "$_" || return
    ctx_class_types=${ctx_class_types-}${ctx_class_types+" "}${1:?}
  }
}

#    Accumulate all Class:libs[<Class>] values and run lib-require with those
#    as arguments, if any.
class_load_libs () # ~ <Class-names...>
{
  test 0 -lt $# || return ${_E_MA:?}
  set -- $(for class in "$@"
      do : "Class__libs[$class]"
        test -n "${!_-}" || continue
        : "${_//,/ }"
        echo "${_// /$'\n'}"
      done | awk '!a[$0]++')
  test 0 -eq $# && return
  $LOG info :uc:class:load-libs "Including sh lib deps" "$#:$*"
  lib_require "$@"
}

class_loaded () # ~ <Class-name>
{
  : "${1:?class-loaded: Class name expected}"
  sh_fun class_${1:?}_
}

#    This is main function used for all class-like call handler behavior.
class_loop () # (SELF-{NAME,ID}) ~ <Item-handler> <Args...>
{
  typeset name type super resolved
  typeset -a CLASS_TYPERES #=( "$SELF_NAME" )

  # TODO: cleanup, see class-resolve
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

    "${1:?class-loop: Item handler expected}" "${@:2}" && resolved=true || {
      test ${_E_done:?} -eq $? && return
      test ${_E_next:?} -eq $_ && continue
      return $_
    }
  done

  "${resolved:-false}" || return ${_E_not_found:?}
}

class_methods () # (name) ~
{
  class_cre='^ *\K[A-Za-z0-9\|\ _\.-]*(?=\)$)' class_calls
}

# The 'new' handler. Initialize a new instance of Type, the lib-init hook
# defines 'create' to defer to this.
class_new () # ~ <Var-name> [<Class-name>] [<Constructor-Args...>]
{
  typeset var type=${2:-Class}
  var=${1:?class-new: Variable name expected}
  test $# -gt 1 && shift 2 || shift

  sh_fun class.${type:?} || {
    : "type=$type;var=$var"
    $LOG error :class-init "No such class defined" "$_" 1 || return
  }

  # Find new ID for instance
  typeset new_prefix="class.${type:?} $type $RANDOM "
  while $new_prefix.defined
  do
    new_prefix="class.$type $type $RANDOM "
  done

  # Call constructor(s) and store concrete type and optional params for Id
  $new_prefix.__init__ "${type:?}" "$@" &&
    $LOG debug :class-new "Complete" "$new_prefix.__init__:$*" ||
    $LOG error :class-new "Running constructors" "E$?:$new_prefix.__init__:$*" $? || return

  # Keep ref key for new class instance at given variable name
  var_set "$var" "$new_prefix"
}

# Return zero status when Class matches Class:instance[id], and else update
# setting and return E:done status.
class_query () # (id) ~ <Class-name>
{
  typeset type=${Class__instance[$id]}
  test "${1:?class-query: Class name expected}" = "$type" || {
    test -n "${Class__type[$1]-}" &&
    $LOG info "" "Changing class" "$id:$type->$1" &&
    type=$1 &&
    typeset -g "Class__instance[$id]=$type" &&
    return ${_E_done:?}
  } ||
    $LOG alert "" "Query failed" "id=$id:type=$1:E$?" $?
}

# XXX: cleanup, class-loop only needs sequence, no pairs
class_resolve () # ~ <Class-name>
{
  typeset i n class
  typeset -a rc
  rc=( ${Class__type[${1:?class-resolve: Class name expected}]//:/ } )
  n=$(( ${#rc[@]} - 1 ))
  for i in "${!rc[@]}"
  do
    class=${rc[i]}
    sh_fun class_${class}_ || continue
    test $n -gt $i && super="${rc[$(( i + 1 ))]}" || super=
    echo $class $super
  done
}

class_run_call () # (id,self,super,call) ~ <Args...>
{
  class_${CLASS_NAME:?}_ "$@"
}

class_static_mro () # ~ <Class-name>
{
  test 1 -eq $# || return ${_E_GAE:?}
  typeset type
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
    typeset r=$? lk=":${CLASS_NAME:?}$call:$OBJ_ID"
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
# to given type. This wraps class-query
class_switch () # (id) ~ <Var-name> [<Class-name>]
{
  typeset var=${1:?class-switch: Variable name expected} type
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
    * ) typeset -g $var="$_"
  esac
  $LOG info :class-switch "Class reference updated" "$_" $?
}

class_typeset () # (name) ~
{
  typeset -f class_${CLASS_NAME:?}_
}

#
