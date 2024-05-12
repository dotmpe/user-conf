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
  lib_require os sys assert lib-uc std-uc || return
  # Reserved characters for calls (for entire call name)
  class_uc_cch='_.-+='
  class_uc_cchre='_\.\-\+\*\!&\$\^%#=/'
  # Reserved characters for static call names (initial character)
  class_uc_scch='-@'
  # Add to class-types for auto initialization on class-init default
  ctx_class_types=${ctx_class_types-}${ctx_class_types+" "}Class\ ParameterizedClass
  # basic static global env required during loading
  declare -gA Class__{attrmap,attrs,field,hook,libs,rel_types,static_{calls,type},type}
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
    .attr-refs ) # ~ ~ [<Names>]
        : about "Build list of variable references"
        : about "Assuming that attributes are all unique names"
        local attr class_word
        # XXX: may want to cache attr list per type in Class:attrs, but see
        # about performance difference before that later.
        $self.attr-tab &&
        for attr
        do
          test -n "${Class__attrmap["$attr"]-}" ||
            $LOG error "$lk$call" "No such attribute" "$attr" ${_E_script:?} || return
          class_word=$(str_word "$_") || return
          printf ' %s=%s__%s["%s"]' \
            "${attr:?}" "${class_word:?}" "${attr:?}" "$OBJ_ID"
        done
      ;;
    .attr-tab ) # ~ ~ [<Array-name>]
        : about "Fill table with class-attribute pairs for current type"
        local -n ATTRMAP=${1:-"Class__attrmap"}
        if_ok "$(class_loop class_attributes)" &&
        while read -r class attr
        do
          ATTRMAP["${attr:?}"]=${class:?}
        done <<< "$_"
      ;;
    .defined ) [[ "set" = "${Class__instance[$id]+"set"}" ]] ||
        return ${_E_nsk:?} ;;
    .class ) echo "${SELF_NAME:?}" ;;
    .class-attributes | .attr@pairs ) class_loop class_attributes ;;
    .class-call-info ) class_call_info ;;
    .class-type ) class_loop class_type ;;
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
    .switch-class ) # ~ <Var-name> [<Class-name>]
        [[ 2 -le $# ]] || return ${_E_GAE:?}
        ! sys_debug diag || class_assert_ref "$2" || return
        [[ 1 -eq $# ]] || {
          class_defined "${2:?}" || class_init "$_" ||
          $LOG debug "$lk" "Cannot switch to missing class" "E$?:$#:$*" $? ||
          return
        }
        $LOG debug "$lk" "Switching class" "$#:$*"
        class_switch "$@"
      ;;
    .set-attr )
        [[ $# -ge 2 && $# -le 3 ]] || return ${_E_MA:?}
        : "${1:?}"
        : "${1//:/__}"
        : "${3:-Class}__${_//-/_}[${id:?}]"
        declare -g "$_"="$2"
        $LOG debug "${lk-}:Class:set-attr" "Updated attribute" "E$?:$_" $?
      ;;
    .toString | \
    .default | \
    .info ) class_call_info ;;

    # XXX: field patterns, special calls, see class.XContext
    # path
    #.*.* )
    #    : "${call:1}"
    #    field_name=${_%%.*}
    #    Class__field[${SELF_NAME:?}.${field_name:?}]
    #  ;;
    # assigment
    #= )
    #  ;;
    #.*+= )
    #    : "${call:1}"
    #    : "${_%+=}"
    #  ;;
    #.*= )
    #    : "${call:1}"
    #    : "${_%=}"
    #    field_name=${_%%@*}
    #  ;;

    #.*@* )
    #    declare ref field_name var_name
    #    : "${call:1}"
    #    field_name=${_%%@*}
    #    ref="Class__field[${SELF_NAME:?}.${field_name:?}]"
    #    var_name=${call#*@}
    #    [[ -z "$var_name" ]] && echo "$ref" || declare -n "$var_name=$ref"
    #  ;;


    # Static helpers, for during declaration & other non-object envs
    # Some of these requite static-class env, see uc-class-d

    --fields ) # ~ ~ <Field-names...>
        : about 'Register attribute field name for current static class'
        :
        declare class_word=${class_static:?} &&
        str_vword class_word &&
        set -- $(str_words "$@") &&
        declare fn &&
        for fn
        do
          # FIXME: compgen will not list declared but uninitialized. On the
          # other hand, arrays initialized to empty and not '()' makes that
          # ${var[*]+set} idiom works properly to detect declared but empty
          # array-type variables. The downside is that there is always a
          # null-string key in the array.
          # ALSO: The [*] infix is required for associative arrays like these,
          # but for regular indexed arrays it would not be needed.
          declare -gA "${class_word}__${fn:?}=()"
        done
      ;;

    --hooks ) # ~ ~ <Hook-names...>
        : about 'Register global class declaration hooks to current static class'
        declare -n hooks=Class__hook &&
        declare hn &&
        for hn
        do hooks[$hn]=${class_static:?}
        done
      ;;

    --libs ) # ~ ~ <Lib-names...>
        : about 'Register prerequisite libraries for instances of class'
        if_ok "$(str_join , "$@")" &&
        Class__libs["${class_static:?}"]="$_"
      ;;

    --ref ) # ~ ~ <Object-id>
        : about 'Static helper to get reference to object'
        local id=${1:?} type
        local -n cparam="Class__instance[\"$id\"]"
        type=${cparam// *}
        : "class.${type:?} $type $id "
        echo "$_"
      ;;

    --rel-types ) # ~ ~ <Rel-types...>
        : about 'Register related types for static class'
        if_ok "$(str_join , "$@")" &&
        Class__rel_types["${class_static:?}"]="$_"
      ;;

    --relate ) # ~ <Attr> <Type> <args...>
        # XXX:
        Class__field[${1:?}]
        uc_class_d --rel-types "${2:?}"
      ;;

    --type ) # ~ ~ <Class-name> <Base-types...>
        : about 'Register class-name as type with base-types'
        declare cn=${1:?} bt
        [[ 1 -lt $# ]] && bt=$(str_join : "${@:2}") || bt=Class
        Class__static_type["${cn:?}"]=$cn:${bt:?}
      ;;

    * ) return ${_E_next:?"$(sys_exc class-uc.lib:@class-: "Expected")"}

  esac && return ${_E_done:?"$(sys_exc class-uc.lib:@class-: "Expected")"}
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
  lib_require uc-class &&
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
              $LOG error "${lk-}:pclass:init" "Set constructor property" "E$?:$1" $? ||
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

    * ) return ${_E_next:?"$(sys_exc class-uc.lib:@parameterizedclass-: "Expected")"}

  esac && return ${_E_done:?"$(sys_exc class-uc.lib:@parameterizedclass-: "Expected")"}
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


class_assert_ref ()
{
  assert rematch "$1" '^[A-Za-z0-9\/\.+-]+$' "${2-Illegal class ref}"
}

class_assert_name ()
{
  assert rematch "$1" '^[A-Za-z0-9_]+$' "${2-Illegal class name}"
}

# Helper for class-attributes that lists all variables for current class
# context.
class_attributes () # (self) ~
{
  declare attr attrs=() c npref
  npref=$(str_word "${CLASS_NAME:?}")__
  c=${#npref}
  if_ok "$(compgen -A variable ${npref:?})" || return 0
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
class_call_info () # (name,id) ~ ... # Print Id info for current class context
{
  echo "class.${CLASS_NAME:?} ${SELF_NAME:?} ${OBJ_ID:?} ${call:?}"
}

# Helper for class-loop that lists all accepted calls for current class context.
# See also class-methods and class-attributes.
class_calls () # (name) ~ ...
{
  declare call calls=() re class_word
  # Retrieve case-items by grep on typeset
  re=${class_cre:-"^ *\K[A-Za-z0-9\|\ $class_uc_cchre]*(?=\)$)"}
  class_word=$(str_word "${CLASS_NAME:?}")
  if_ok "$(declare -f class_${class_word}_ | grep -Po "$re")" &&
  test -n "$_" ||
    return ${_E_next:?"$(sys_exc class-uc.lib:-calls: "Expected")"}
  # Read result into array and output line-by-line together with class
  <<< "$_" mapfile -t calls &&
  for call in "${calls[@]}"
  do
    echo "$CLASS_NAME $call"
  done
}

class_cache_mro () # ~ <Class-name> # Concat static-type for type and basetypes
{
  : "${1:?"$(sys_exc class-uc.lib:compile-mro "Class name expected")"}"
  : "Class__type[$_]"
  [[ "${!_-}" ]] || {
    if_ok "$(class_static_mro "${1:?}" | tac | remove_dupes | tac )" || return
    declare -g "Class__type[${1:?}]=${1:?}${_:+:}${_//$'\n'/:}"
  }
}

class_type () # ~
{
  echo "${CLASS_NAME:?}"
}

# XXX: calls are invocations of methods (looked up on MRO) for object instances,
# static calls, and a helper to run calls on super from a current object
# instance.
# FIXME: invoke methods in static class context
class_define () # ~ <Class-name> # Generate function to wrap class calls
{
  declare class=${1:?class-define: Class name expected}
  ! sys_debug diag || class_assert_ref "$class" || return

  : "
class.$class ()
{
  local lk=\${lk-}:class.$class

  [[ $class = \${1:?\"\$(sys_exc class-uc.lib/@$class: \"Expected\")\"} ]] && {
    # Start new call resolution

    : \${2:?\"\$(sys_exc class-uc.lib/@$class: \"Id Expected\")\"}
    declare SELF_NAME=$class OBJ_ID=\$2 call=\${3:-.toString} self id super \
      CLASS_{NAME,IDX,TYPERES,TYPEC}
    id=\$OBJ_ID
    self=\"class.$class $class \$id \"

    [[ 2 -lt \$# ]] && shift 3 || shift 2

    class_loop class_run_call \"\$@\"
    return

  } || {

    # XXX: Allow static call based on select prefix characters?
    str_globmatch \"\${1:0:1}\" \"[:-]\" && {
      declare call=\$1
      shift
      class_${class//[^A-Za-z0-9_]/_}_ \"\$@\"
      return

    } || {

      # Do invocation at super type, for existing class env
      declare super_type=\${1:?} call=\${2:?} super &&
      shift 2 &&
      class_loop_continue class_run_call \"\$@\"
    }
  }
}
"
  eval "$_"
}

class_define_all () # ~ [<Class-names...>]
{
  [[ 0 -lt $# ]] || set -- ${ctx_class_types:?}
  : "${@:?"$(sys_exc class-uc.lib:-define-all: "Class names expected")"}"

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
    class_cache_mro "$class" || return
  done

  for class
  do
    sh_fun class.$class || class_define "$class" || return
  done
}

# FIXME: would rather test assoc-array than look for function
class_defined () # ~ <Name>
{
  : "${1:?"$(sys_exc class-uc.lib:-defined "Class name expected")"}"
  sh_fun class.$_
}

# Destructor for previously initialized class instance variables
class_del () # ~ <Var-name>
{
  : "${1:?"$(sys_exc class-uc.lib:-del "Variable name expected")"}"
  #if_ok "$(${!1}.instance)" &&
  ${!_:?"$(sys_exc class.lib:-del: "Instance reference expected")"}.__del__ &&
  unset $1
}

class_exists () # ~ <Class-name>
{
  : "${1:?"$(sys_exc class-uc.lib:-exists "Class name expected")"}"
  [[ "${Class__static_type[$_]:-}" ]]
}

class_find () # ~ <Class-names...>
{
  local class
  for class
  do
    class_load_def "$class" ||
      sys_astat -eq ${_E_not_found:-127} && {
        ! sys_debug || $LOG debug "${lk-}" "No such class" "$class"
        continue
      } || return $?
    class_load "$class" ||
      $LOG error "${lk-}" "Exception loading class" "E$?:$class:$(sys_callers)" $?
  done
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
  local lk=${lk-}:class-uc.lib:-init
  $LOG info "$lk" "Loading static class env" "$#:$*"
  ! sys_debug diag ||
    for ref
    do class_assert_ref "$ref" || return
    done
  class_load_everything "${@:?class-init: Class names expected}" &&
  # Now that call classes are loaded, makes sure all on MRO and related are
  # fully defined.
  declare -a bases &&
  if_ok "$(for class
    do
      ! sys_debug diag || class_assert_ref "$class" || return
      class_static_mro "$class" || return
    done | awk '!a[$0]++')" &&
  <<< "$_" mapfile -t bases &&
  class_define_all "$@" "${bases[@]}" &&
  $LOG debug "$lk" "Prepared class env OK" "$#:$*"
}

class_instance () # ~ <Ref> # Check for valid object reference
{
  local obj_id type ref=${1:?}
  ref=${ref#* }; type=${ref%% *}; ref=${ref#* }; obj_id=${ref%% *}

  class_exists "$type" &&
  : "${Class__instance[$obj_id]-}" &&
  [[ "$type" = "${_:0:${#type}}" ]]
}

# Load classes (source scripts and run load hooks)
class_load () # ~ [<Class-names...>]
{
  [[ 0 -lt $# ]] || set -- ${ctx_class_types:?}
  declare lk=${lk:-:}${lk:+:}uc:class-load
  declare class class_name
  # Source scripts and run class 'load' hooks
  for class in "${@:?$lk: Class names expected}"
  do
    class_assert_ref "$class" || return
    class_name=$(str_word "$class")
    class_loaded "$class_name" ||
    class_load_def "$class" ||
      $LOG alert "$lk" "Cannot find such definition" "E$?:$class" $? || return
    class_exists "$class" || {
      sh_fun class_${class_name}__load ||
        $LOG alert "$lk" "Expected class 'load' hook" "$class:$class_name" 1 || return
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

  # XXX: Recurse for base classes
  declare -a bases
  : "${1:?"$(sys_exc "${lk-:}")"}"
  : "${Class__static_type[$_]:?"$(sys_exc "${lk-}:$_")"}"
  <<< "${_//:/$'\n'}" mapfile -t bases &&
  unset "bases[0]" && {
    [[ 0 -eq ${#bases[@]} ]] || class_load_everything "${bases[@]}"
  }
}

#    Try to find sh lib or class.sh file and source that (uses lib-uc.lib).
class_load_def () # (:ref) ~ [<Class-name>]
{
  local lk=${lk-}:uc/class:load-def
  declare -n fn=class_sid cn=class_word
  class_reference "$@" || return

  $LOG debug "$lk" "Looking for definitions" "$fn-class.lib $cn.class"
  # XXX: old method of loading?
  # If class corresponds to lib or other group, require that to be initialized
  lib_uc_islib "$fn-class" && {
    lib_require "$_" && lib_init "$_" ||
      $LOG alert "$lk" "Failed loading class context" \
        "E$?:${1:?}:$_" $? || return
  } || {
    # New method: from .class.sh files
    # (with two optional load hooks, but no init hook)
    declare lib_uc_kin=_class lib_uc_ext=.class.sh
    lib_uc_islib "$fn" || return 127
    lib_require "$_" || return
    ctx_class_types=${ctx_class_types-}${ctx_class_types+" "}${1:?}
  }
}

#    Accumulate all Class:libs[<Class>] values and run lib-require with those
#    as arguments, if any.
class_load_libs () # ~ <Class-names...>
{
  [[ 0 -lt $# ]] || return ${_E_MA:?}
  set -- $(for class
      do ! sys_debug diag || class_assert_ref "$class" || return
        vn="Class__libs[$class]"
        [[ "${!vn+set}" ]] || continue
        : "${!vn//,/ }"
        echo "${_// /$'\n'}"
      done | awk '!a[$0]++')
  [[ 0 -eq $# ]] && return
  local lk=${lk-}:uc/class:load-libs
  $LOG info "$lk" "Including sh lib deps" "$#:$*"
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
      do ! sys_debug diag || class_assert_ref "$class" || return
        vn="Class__rel_types[$class]"
        [[ "${!vn-}" ]] || continue
        : "${!vn//,/ }"
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
      do ! sys_debug diag || class_assert_ref "$class" || return
        vn="Class__rel_types[$class]"
        [[ "${!vn-}" ]] || continue
        : "${!vn//,/ }"
        echo "${_// /$'\n'}"
      done | awk '!a[$0]++')
  [[ 0 -eq $# ]] && return
  class_load "$@"
}

class_loaded () # ~ <Class-name>
{
  : "${1:?class-loaded: Class name expected}"
  # XXX: replace with assert class-name
  class_assert_name "$1" &&
  sh_fun class_${1:?}_
}

#    This is main function used for all class-like call handler behavior.
class_loop () # (SELF-{NAME,ID}) ~ <Item-handler> <Args...>
{
  declare -a CLASS_TYPERES
  : "${Class__type["${SELF_NAME:?}"]//:/ }"
  CLASS_TYPERES=( $_ )

  declare super resolved

  for ((
    CLASS_TYPEC=${#CLASS_TYPERES[@]}, CLASS_TYPEC--, CLASS_IDX=0;
    CLASS_TYPEC >= 0;
    CLASS_IDX++, CLASS_TYPEC--
  ))
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

class_loop_continue ()
{
  local CLASS_TYPEC=${CLASS_TYPEC:?} CLASS_IDX=${CLASS_IDX:?}

  while [[ $CLASS_TYPEC -gt 0 ]]
  do
    CLASS_IDX=$(( CLASS_IDX + 1 ))
    CLASS_NAME="${CLASS_TYPERES[$CLASS_IDX]}"
    CLASS_TYPEC=$(( CLASS_TYPEC - 1 ))
    [[ $CLASS_TYPEC -gt 0 ]] && {
      SUPER_NAME=${CLASS_TYPERES[$(( CLASS_IDX + 1 ))]}
      super="class.${SUPER_NAME:?} ${SELF_NAME:?} "
    } || SUPER_NAME= super=

    #"${1:?class-loop: Item handler expected}" "${@:2}" && resolved=true || {
    "${1:?class-loop: Item handler expected}" "${@:2}" || {
      local r=$?
      [[ ${_E_done:?} -eq $r ]] && return
      [[ ${_E_next:?} -eq $r ]] && continue
      return $r
    }
  done
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
  local lk=${lk-}:class-uc.lib:-new
  declare type=${2:-Class} var
  var=${1:?"$(sys_exc "$lk" "Variable name expected")"}
  [[ $# -gt 1 ]] && shift 2 || shift

  sh_fun class.${type:?} || {
    : "type=$type;var=$var"
    $LOG error "$lk" "No such class defined" "$_" 1 || return
  }

  # Find new ID for instance
  declare new_prefix="class.${type:?} $type $RANDOM "
  while $new_prefix.defined
  do
    new_prefix="class.$type $type $RANDOM "
  done

  # Call constructor(s) and store concrete type and optional params for Id
  $new_prefix.__init__ "${type:?}" "$@" &&
    $LOG debug "$lk" "Complete" "$new_prefix.__init__:$*" ||
    $LOG error "$lk" "Running constructors" "E$?:$new_prefix.__init__:$*" $? ||
    return

  # Keep ref key for new class instance at given variable name
  declare -n ref=$var
  ref="$new_prefix"
}

# Return zero status when Class matches Class:instance[id], and else update
# setting and return E:done status.
# XXX: work in progress
class_query () # (id) ~ <Class-name>
{
  local lk=${lk-}:class-uc.lib:-query
  : "${1:?"$(sys_exc "$lk" "Target class expected")"}"
  declare -n type=Class__instance[${id:?}]
  : "${type:?class-query: Class type expected for #$id}"
  [[ "$1" = "$type" ]] || {
    [[ "${Class__type[$1]-}" ]] &&
    $LOG info "$lk" "Changing class" "$id:$type->$1" &&
    type=$1 &&
    return ${_E_done:?}
  } ||
    $LOG alert "$lk" "Query failed" "id=$id:type=$1:E$?" $?
}

# Update class file and name from ref
# XXX: for now, class-file is only used once and class-name otherwise.
# may want to keep current inputs in env using this, to use original class id
class_reference () # (:ref) ~ [<Class-name>]
{
  [[ "${class_ref-}" ]] ||
    : "${1:?"$(sys_exc class:reference "Class name reference expected")"}"
  [[ "${1+set}" ]] && class_ref=$1
  ! sys_debug assert || class_assert_ref "$class_ref" || return
  local new_class_word=${class_ref//[^A-Za-z0-9_]/_}
  [[ "${class_word-}" = "$new_class_word" ]] || {
    class_word=$new_class_word
    : "${class_word//_/-}"
    class_sid=${_,,}
  }
}

class_run_call () # (id,self,super,call) ~ <Args...>
{
  class_${CLASS_NAME//[^A-Za-z0-9_]/_}_ "$@"
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
    declare r=$? lk="${lk-}:${CLASS_NAME:?}$call:$OBJ_ID"
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
  local lk=${lk-}:class-uc.lib:-switch
  [[ -z "${2-}" ]] ||
    class_query "$2" ||
    class_loop_done ||
      $LOG "$lk" error "No such" "E$?" $? || return
  declare var=${1:?"$(sys_exc "$lk" "Variable name expected")"}
  declare -n obj=$var type="Class__instance[\"$id\"]"
  : "class.${type:?} $type $id "
  test "$obj" = "$_" && return
  obj="$_"
  ! sys_debug ||
    $LOG info "$lk" "Class reference updated" "$var=$obj"
}

class_typeset () # (name) ~
{
  declare -f class_${CLASS_NAME:?}_
}

#
