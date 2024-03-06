# Created: 2020-09-16

## Foundation for class-like behavior and data instances of composite types

#  Class-like behavior for Bash uses global arrays and random, numerical Ids to
#  store types and other attributes of new 'objects', and class_<Class-name>_
#  handler functions to define methods (or other calls) to be performed on
#  such objects.

# See uc-class for util. This lib itself may move to us-class or similar in
# +U-S later.

class_uc_lib__load ()
{
  : about "Foundation for class-like behavior and data instances of composite types"
  lib_require os sys lib-uc std-uc || return
  # Reserved characters for calls (for entire call name)
  class_uc_cch='_.-+='
  class_uc_cchre='_\.\-\+\*\!&\$\^%#='
  # Reserved characters for static call names (initial character)
  class_uc_scch='-@'
  # Add to class-types for auto initialization on class-init default
  ctx_class_types=${ctx_class_types-}${ctx_class_types+" "}Class\ ParameterizedClass
  # basic static global env required during loading
  declare -gA Class__{field,hook,libs,rel_types,static_{calls,type},type}
}

class_uc_lib__init ()
{
  test -z "${class_uc_lib_init:-}" || return $_
  create () { class_new "$@"; }
  destroy () { class_del "$@"; }
  # see class-reference
  declare -g class_{ref,word,sid}
}


# The abstract base class with some helpers.

class_Class__load ()
{
  Class__static_type[Class]=Class
  #Class__static_calls[Class]=exists,hasattr

  # Want to use static hook in Class but none of helpers is declared yet,
  # XXX: see uc-class.lib
  class_static=Class call=--hooks \
    class_Class_ fields hooks libs rel-types type ||
    class_loop_done || return

  # Assoc-array to store concrete type and additional 'params' passed at Class
  # construction
  declare -gA Class__instance
}

class_Class_ () # (call,id,self,super) ~ <Instance-Id> .<Message-name> <Args...>
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
    .defined ) [[ "set" = "${Class__instance[$id]+"set"}" ]] ||
        return ${_E_nsk:?} ;;
    .class ) echo "${SELF_NAME:?}" ;;
    .class-attributes ) class_loop class_attributes ;;
    .class-call-info ) class_call_info ;;
    .class-calls ) class_loop class_calls ;;
    .class-debug )
        class_call_info &&
        $self.class-tree &&
        $self.class-attributes &&
        $self.class-calls
      ;;
    .class-info ) class_info ;;
    .class-methods ) class_loop class_methods ;;
    .class-names ) class_names ;;
    .class-resolve ) class_resolve "${SELF_NAME:?}" ;;
    .class-tree )
        class_loop class_names | {
          # XXX: turns it into a single indented branch
          declare ind=0
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
    .switch-class )
        [[ 2 -le $# ]] || return ${_E_GAE:?}
        [[ 1 -eq $# ]] || {
          class_defined "${2:?}" || class_init "$_" || return
        }
        class_switch "$@"
      ;;
    .set-attr )
        [[ $# -ge 2 && $# -le 3 ]] || return ${_E_MA:?}
        : "${1:?}"
        : "${1//:/__}"
        : "${3:-Class}__${_//-/_}[${id:?}]"
        declare -g "$_"="$2"
        $LOG debug : "Updated attribute" "E$?:$_" $?
      ;;
    .toString | \
    .default | \
    .info ) class_call_info ;;

    # XXX: field patterns
    # path
    .*.* )
        : "${call:1}"
        field_name=${_%%.*}
        Class__field[${SELF_NAME:?}.${field_name:?}]
      ;;
    # assigment
    = )
      ;;
    .*+= )
        : "${call:1}"
        : "${_%+=}"
      ;;
    .*= )
        : "${call:1}"
        : "${_%=}"
        field_name=${_%%@*}
      ;;
    # reference/alias
    .*@* )
        declare ref field_name var_name
        : "${call:1}"
        field_name=${_%%@*}
        ref="Class__field[${SELF_NAME:?}.${field_name:?}]"
        var_name=${call#*@}
        [[ -z "$var_name" ]] && echo "$ref" || declare -n "$var_name=$ref"
      ;;

    # XXX: static helpers for during declaration

    --libs )
        if_ok "$(str_join , "$@")" &&
        Class__libs[${class_static:?}]="$_"
      ;;

    --fields )
        set -- $(str_words "$@") &&
        declare fn &&
        for fn
        do
          declare -gA "${class_static:?}__${fn:?}=()"
        done
      ;;

    --hooks )
        declare -n hooks=Class__hook &&
        declare hn &&
        for hn
        do hooks[$hn]=${class_static:?}
        done
      ;;

    --relate )
        Class__field[${1:?}]
        uc_class_d --rel-types "${2:?}"
      ;;

    --rel-types )
        if_ok "$(str_join , "$@")" &&
        Class__rel_types[${class_static:?}]="$_"
      ;;

    --type )
        set -- $(str_words "$@") &&
        declare cn=${1:?} && shift || return
        [[ 0 -lt $# ]] && bt=$(str_join : "$@") || bt=Class
        Class__static_type[${cn:?}]=$cn:${bt:?}
      ;;

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
  uc_class_declare ParameterizedClass Class &&
  #--params
  #  $ctx_pclass_params
  #Class__static_type[ParameterizedClass]=ParameterizedClass:Class
  [[ -z "${ctx_pclass_params-}" ]] && return
  declare p
  for p in $ctx_pclass_params
  do
    declare -g -A "ParameterizedClass__params__${p:?}=()" || return
  done
}

class_ParameterizedClass_ () # (call,id,self,super) ~ <Instance-Id> .<Message-name> <Args...>
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
        while [[ 0 -lt $# ]]
        do str_globmatch "${1:?}" "*=*" && {
            $self.setp "${1%%=*}" "${1#*=}" ||
              $LOG error :pclass:init "Set constructor property" "E$?:$1" $? ||
              return
          } || argv+=( "$1" )
          shift
        done
        set -- "${argv[@]}"
        unset argv
        class_super_optional_call "$@"
      ;;

    ( .class-params )
        compgen -A variable ${CLASS_NAME:?}__params__
      ;;

    # Get/set'er access for ParameterizedClass params.
    ( .setp )
        declare -g "ParameterizedClass__params__${1:?}[$id]=$2"
      ;;
    ( .getp )
        : "ParameterizedClass__params__${1:?}[$id]"
        "${parkey_exists:-true}" "$_" && echo "${!_}" || echo "${!_:-}"
      ;;
    ( .param ) [[ 2 -ge $# ]] || return ${_E_GAE:-193}
        [[ 2 -eq $# ]] && {
          $self.setp "$@" || return
        } ||
          $self.getp "$@" ;;
    ( .parkey )
        echo "ParameterizedClass__params__${1:?}[$id]"
      ;;

      * ) return ${_E_next:?}

  esac && return ${_E_done:?}
}

# Variant on mparams that takes default value from a static context
class_ParameterizedClass_cparams () # (id,static-ctx) ~ <Class-params-var> <Message> ...
{
  ! str_globmatch " ${!1:?} " "* ${2:?} *" && return ${_E_next:-196}
  [[ 3 -ge $# ]] || return ${_E_GAE:-193}
  declare parkey="ParameterizedClass__params__${2:?}[$OBJ_ID]"
  [[ 3 -eq $# ]] && {
    declare -g "$parkey=$3" || return
  } || {
    [[ set = "${!parkey+set}" ]] && {
      echo "${!parkey}"
    } ||
      $static_ctx$2 "${@:3}" || return
  }
}

# Helper to map a method call to get/set a parameter directly from/to the array
class_ParameterizedClass_mparams () # (id) ~ <Class-params-var> <Message> ...
{
  ! str_globmatch " ${!1:?} " "* ${2:?} *" && return ${_E_next:-196}
  [[ 3 -ge $# ]] || return ${_E_GAE:-193}
  declare parkey="ParameterizedClass__params__${2:?}[$OBJ_ID]"
  [[ 3 -eq $# ]] && {
    declare -g "$parkey=$3" || return
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
  declare attr attrs=() c=${#_}
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
  declare class subclass
  for class in "${@:?class-bases: Class names expected}"
  do
    : "Class__static_type[$class]"
    [[ "${!_-}" ]] || return
    echo "$class"
    if_ok "$(
      for subclass in $_
      do str_wordmatch "$subclass" "$@" ||
        echo "$subclass"
      done)" || return

    class_bases $_ || return
  done
}

# Helper to print current call info, shows current class context.
class_call_info () # (name,id) ~ # Print Id info for current class context
{
  echo "class.${CLASS_NAME:?} ${SELF_NAME:?} ${OBJ_ID:?} ${call:?}"
}

# Helper for class-loop that lists all accepted calls for current class context.
# See also class-methods and class-attributes.
class_calls () # (name) ~
{
  declare call calls=() re
  re=${class_cre:-"^ *\K[A-Za-z0-9\|\ $class_uc_cchre]*(?=\)$)"}
  if_ok "$(declare -f class_${CLASS_NAME:?}_ | grep -Po "$re")" &&
  test -n "$_" || return ${_E_next:?}
  <<< "$_" mapfile -t calls &&
  for call in "${calls[@]}"
  do
    echo "$CLASS_NAME $call"
  done
}

class_compile_mro () # ~ <Class-name>
{
  : "${1:?"$(sys_exc class-uc.lib:compile-mro "Class name expected")"}"
  : "Class__type[$_]"
  [[ "${!_-}" ]] || {
    if_ok "$(class_static_mro "${1:?}" | tac | remove_dupes | tac )" || return
    declare -g "Class__type[${1:?}]=${1:?}${_:+:}${_//$'\n'/:}"
  }
}

class_define () # ~ <Class-name> # Generate function to call 'class methods'
{
  declare class=${1:?class-define: Class name expected}
  : "
class.$class () {
  [[ $class = \${1:?} ]] && {
    # Start new call resolution

    declare SELF_NAME=$class OBJ_ID=\${2:?} call=\${3:-.toString} self id \
      CLASS_{IDX,TYPERES,TYPEC}
    id=\$OBJ_ID
    self=\"class.$class $class \$id \"

    [[ 2 -lt \$# ]] && shift 3 || shift 2

    class_loop class_run_call \"\$@\"
    return

  } || {

    # Allow static call based on select prefix characters
    str_globmatch \"\${1:0:1}\" \"[:-]\" && {
      declare call=\$1
      shift

    } || {
      # Make call for this object at super types

      CLASS_IDX=\$(( CLASS_IDX + 1 ))
      [[ $class = \"\${CLASS_TYPERES[\$CLASS_IDX]}\" ]] || {
        $LOG alert : Mismatch \"\$CLASS_IDX:$class!=\${CLASS_TYPERES[\$CLASS_IDX]}:\$*\"
        return 1
      }
      CLASS_NAME=$class
      CLASS_TYPEC=\$(( CLASS_TYPEC - 1 ))
      [[ \$CLASS_TYPEC -gt 0 ]] && {
        SUPER_NAME=\${CLASS_TYPERES[\$(( CLASS_IDX + 1 ))]}
        super=\"class.\${SUPER_NAME:?} \${SELF_NAME:?} \"
      } || SUPER_NAME= super=

      declare call=\${2:-.toString}
      shift 2
    }

    class_${class}_ \"\$@\"
  }
}
"
  eval "$_"
}

class_define_all () # ~ <Class-names...>
{
  [[ 0 -lt $# ]] || set -- ${ctx_class_types:?}
  : "${@:?class-define-all: Class names expected}"

  # Skip if already defined
  set -- $(filter_args "not class_defined" "$@")
  [[ 0 -eq $# ]] && return

  declare class bases def

  # XXX: unused, but allows class_<Type>_bases callback (iso. class load hook
  # with Class:static-type declaration).
  for class in
  do
    def="Class__static_type[$class]"
    [[ "${!def-}" ]] || {
      ! sh_fun class_${class}__bases &&
      bases=$class:Class || {
        bases=$(class_${class}__bases) || return
      }
      declare -g "$def=$bases" || return
    }
  done

  for class
  do
    class_compile_mro "$class" || return
  done

  for class
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
  [[ "${Class__static_type[${1:?class-exists: Class name expected}]:-}" ]]
}

class_info () # (name,id) ~ # Print Id info for current class context
{
  echo "class.${CLASS_NAME:?} ${SELF_NAME:?} ${OBJ_ID:?}"
}

#    Prepare everything for given classes to create new instances using
#    class-new. This includes:
#      - class-load
#      - class-define-all, for given classes and all base types
class_init () # ~ <Class-names...>
{
  $LOG info :class.lib:init "Loading static class env" "$#:$*"
  class_load_everything "${@:?class-init: Class names expected}" &&
  # Now that call classes are loaded, makes sure all on MRO and related are
  # fully defined.
  declare -a bases &&
  if_ok "$(for class
    do class_static_mro "$class" || return
    done | awk '!a[$0]++')" &&
  <<< "$_" mapfile -t bases &&
  class_define_all "$@" "${bases[@]}" &&
  $LOG debug :class.lib:init "Prepared class env OK" "$#:$*"
}

# Load classes (source scripts and run load hooks)
class_load () # ~ [<Class-names...>]
{
  [[ 0 -lt $# ]] || set -- ${ctx_class_types:?}
  declare lk=${lk:-:}${lk:+:}uc:class-load
  declare class

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
}

# Load classs and prerequisite libs.
class_load_everything ()
{
  class_load "$@" || return

  # Load prerequisites (libs and classes)
  class_load_prereq "$@" &&
  class_init_prereq "$@" || return
  #$LOG debug "$lk" "Done loading additional prerequisites" "$*"

  # Recurse for base classes
  declare -a bases
  <<< "${Class__static_type[${1:?}]//:/$'\n'}" mapfile -t bases &&
  unset "bases[0]" && {
    [[ 0 -eq ${#bases[@]} ]] || class_load_everything "${bases[@]}"
  }
}

#    Try to find sh lib or class.sh file and source that (uses lib-uc.lib).
class_load_def () # (:ref) ~ [<Class-name>]
{
  declare -n fn=class_sid cn=class_word
  class_reference "$@" || return
  $LOG debug : "Looking for definitions" "$fn-class.lib $cn.class"
  # XXX: old method of loading?
  # If class corresponds to lib or other group, require that to be initialized
  lib_uc_islib "$fn-class" && {
    lib_require "$_" && lib_init "$_" ||
      $LOG alert :uc:class:load-def "Failed loading class context" \
        "E$?:${1:?}:$_" $? || return
  } || {
    # New method: from .class.sh files
    # (with two optional load hooks, but no init hook)
    declare lib_uc_kin=_class lib_uc_ext=.class.sh
    lib_uc_islib "$fn" || return 127
    lib_require "$_" || return
    ctx_class_types=${ctx_class_types-}${ctx_class_types+" "}${cn:?}
  }
}

#    Accumulate all Class:libs[<Class>] values and run lib-require with those
#    as arguments, if any.
class_load_libs () # ~ <Class-names...>
{
  [[ 0 -lt $# ]] || return ${_E_MA:?}
  set -- $(for class
      do : "Class__libs[$class]"
        [[ -n "${!_-}" ]] || continue
        : "${_//,/ }"
        echo "${_// /$'\n'}"
      done | awk '!a[$0]++')
  [[ 0 -eq $# ]] && return
  $LOG info :uc:class:load-libs "Including sh lib deps" "$#:$*"
  lib_require "$@"
}

class_load_prereq ()
{
  class_load_libs "$@" &&
  class_load_types "$@"
}

class_init_prereq ()
{
  [[ 0 -lt $# ]] || return ${_E_MA:?}
  set -- $(for class
      do vr="Class__rel_types[$class]"
        [[ "${!vr-}" ]] || continue
        : "${!vr//,/ }"
        echo "${_// /$'\n'}"
      done | awk '!a[$0]++')
  [[ 0 -eq $# ]] && return
  class_init "$@"
}

class_load_types ()
{
  [[ 0 -lt $# ]] || return ${_E_MA:?}
  local x=$*
  set -- $(for class
      do : "Class__rel_types[$class]"
        [[ "${!_-}" ]] || continue
        : "${_//,/ }"
        echo "${_// /$'\n'}"
      done | awk '!a[$0]++')
  [[ 0 -eq $# ]] && return
  class_load "$@"
}

class_loaded () # ~ <Class-name>
{
  : "${1:?class-loaded: Class name expected}"
  sh_fun class_${1:?}_
}

#    This is main function used for all class-like call handler behavior.
class_loop () # (SELF-{NAME,ID}) ~ <Item-handler> <Args...>
{
  declare name type super resolved
  declare -a CLASS_TYPERES #=( "$SELF_NAME" )

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
    [[ $CLASS_TYPEC -gt 0 ]] && {
      SUPER_NAME=${CLASS_TYPERES[$(( CLASS_IDX + 1 ))]}
      super="class.${SUPER_NAME:?} ${SELF_NAME:?} "
    } || SUPER_NAME= super=

    "${1:?class-loop: Item handler expected}" "${@:2}" && resolved=true || {
      local r=$?
      [[ ${_E_done:?} -eq $r ]] && return
      [[ ${_E_next:?} -eq $r ]] && continue
      return $r
    }
  done

  "${resolved:-false}" || return ${_E_not_found:?}
}

class_loop_done () # ~ [<Status>]
{
  local r=$?
  [[ ${_E_done:?} -eq ${1:-$r} ]] || return $r
}

class_methods () # (name) ~
{
  class_cre='^ *\K[A-Za-z0-9\|\ _\.-]*(?=\)$)' class_calls
}

class_names () # (name,id) ~ # Print names info for current class context
{
  echo "class.${CLASS_NAME:?} ${SELF_NAME:?}"
}

# The 'new' handler. Initialize a new instance of Type, the lib-init hook
# defines 'create' to defer to this.
class_new () # ~ <Var-name> [<Class-name>] [<Constructor-Args...>]
{
  declare type=${2:-Class} var=${1:?class-new: Variable name expected}
  [[ $# -gt 1 ]] && shift 2 || shift

  sh_fun class.${type:?} || {
    : "type=$type;var=$var"
    $LOG error :class-init "No such class defined" "$_" 1 || return
  }

  # Find new ID for instance
  declare new_prefix="class.${type:?} $type $RANDOM "
  while $new_prefix.defined
  do
    new_prefix="class.$type $type $RANDOM "
  done

  # Call constructor(s) and store concrete type and optional params for Id
  $new_prefix.__init__ "${type:?}" "$@" &&
    $LOG debug :class-new "Complete" "$new_prefix.__init__:$*" ||
    $LOG error :class-new "Running constructors" "E$?:$new_prefix.__init__:$*" $? || return

  # Keep ref key for new class instance at given variable name
  declare -n ref=$var
  ref="$new_prefix"
}

# Return zero status when Class matches Class:instance[id], and else update
# setting and return E:done status.
# XXX: work in progress
class_query () # (id) ~ <Class-name>
{
  : "${1:?class-query: Target class expected}"
  declare -n type=Class__instance[${id:?}]
  : "${type:?class-query: Class type expected for #$id}"
  [[ "$1" = "$type" ]] || {
    [[ "${Class__type[$1]-}" ]] &&
    $LOG info "" "Changing class" "$id:$type->$1" &&
    type=$1 &&
    return ${_E_done:?}
  } ||
    $LOG alert "" "Query failed" "id=$id:type=$1:E$?" $?
}

# Update class file and name from ref
# XXX: for now, class-file is only used once and class-name otherwise.
# may want to keep current inputs in env using this, to use original class id
class_reference () # (:ref) ~ [<Class-name>]
{
  [[ "${class_ref-}" ]] ||
    : "${1:?"$(sys_exc class:reference "Class name reference expected")"}"
  [[ -z "${1-}" ]] || class_ref=$1
  local new_class_word=${class_ref//[^A-Za-z0-9_]/_}
  [[ "${class_word-}" = "$new_class_word" ]] || {
    class_word=$new_class_word
    : "${class_word//_/-}"
    class_sid=${_,,}
  }
}

# XXX: cleanup, class-loop only needs sequence, no pairs
class_resolve () # ~ <Class-name>
{
  declare i n class
  declare -a rc
  rc=( ${Class__type[${1:?class-resolve: Class name expected}]//:/ } )
  n=$(( ${#rc[@]} - 1 ))
  for i in "${!rc[@]}"
  do
    class=${rc[i]}
    sh_fun class_${class}_ || continue
    [[ $n -gt $i ]] && super="${rc[$(( i + 1 ))]}" || super=
    echo $class $super
  done
}

class_run_call () # (id,self,super,call) ~ <Args...>
{
  class_${CLASS_NAME:?}_ "$@"
}

class_static_mro () # ~ <Class-name>
{
  [[ 1 -eq $# ]] || return ${_E_GAE:?}
  declare type
  set -- ${Class__static_type[${1:?}]//:/ }
  shift
  while [[ 0 -lt $# ]]
  do
    type="$1"
    echo "$1"
    shift
    [[ -z "${Class__static_type[$type]-}" ]] || {
      : "${Class__static_type[$type]-}"
      set -- ${_//:/ } "$@"
      shift
    }
  done
}

class_super_optional_call () # (id,self,super,call) ~ <Args...>
{
  [[ -z "$super" ]] || $super$call "$@" || {
    declare r=$? lk=":${CLASS_NAME:?}$call:$OBJ_ID"
    class_loop_done $r && {
      $LOG debug "$lk" "Superclass call done" \
          "E$r:${SELF_NAME:?}::${CLASS_TYPERES[*]}"
          #"E$r:${SELF_NAME:?}"
      return
    }
    [[ ${_E_next:?} -eq $r ]] && {
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
  declare var=${1:?class-switch: Variable name expected} type
  case "$var" in
    local:* ) var="${var:6}" ;
  esac
  [[ -z "${2-}" ]] ||
    class_query "$2" ||
    class_loop_done || return
  type=${Class__instance[$id]}
  : "class.${type:?} $type $id "
  test "${!var}" = "$_" && return
  case "$1" in
    local:* ) eval "$var=\"$_\"" ;;
    * ) declare -g $var="$_"
  esac
  $LOG info :class-switch "Class reference updated" "$_" $?
}

class_typeset () # (name) ~
{
  declare -f class_${CLASS_NAME:?}_
}

#
