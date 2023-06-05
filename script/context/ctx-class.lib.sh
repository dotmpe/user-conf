#!/usr/bin/env bash
# Created: 2020-09-16

ctx_class_lib__load ()
{
  ctx_class_types=${ctx_class_types-}${ctx_class_types+" "}Class
}

ctx_class_lib__init ()
{
  test -z "${ctx_class_lib_init:-}" || return $_

  create() { class.init "$@"; }
  destroy() { class.deinit "$@"; }
  class.load
}


# Destructor for previously initialized class instance variables
class.deinit () # ~ <Var-name>
{
  if_ok "$(${!1}.class)" &&
  ${!1}.__$_ &&
  unset $1
}

# Helper for class functions
class.info () # ~ # Print human readable Id info for current class context
{
  echo "class.$name <#$id> ${Class__instances[$id]:?Expected class instance #$id}"
}

# The 'new' handler. Initialize a new instance of Type, the lib-init hook
# defines 'create' to defer to this.
class.init () # ~ <Var-name> [<Type>] [<Constructor-Args...>]
{
  local var=${1:?} type=${2:-Class}
  test $# -gt 1 && shift 2 || shift

  # Find new ID for instance
  local new_prefix="class.$type $RANDOM "
  while $new_prefix.defined
  do
    new_prefix="class.$type $RANDOM "
  done

  # Call constructor(s) and store concrete type and optional params for Id
  $new_prefix.$type "$type" "$@" ||
    $LOG error : "Calling constructor" "E$?:$new_prefix.$type:$*" $? || return

  # Keep ref key for new class instance at given variable name
  case "$var" in
    local:* ) eval "${var:6}=\"$new_prefix\"" ;;
    * ) declare -g $var="$new_prefix" ;;
  esac
  # NOTE: above global declaration would not work for local vars, and Bash<=5.0
  # cannot tell wether $var already is declared local in an outter function
  # scope. Even more declare or set are useless, so its eval to the rescue.
}

# Run load handler for every class to declare global vars of each
class.load ()
{
  for class in $ctx_class_types
  do sh_fun class.$class.load || continue
    class.$class.load ||
      $LOG error : "During class load" "E$?:$class" $? || return
  done
}

# Helper for class functions
class.info-tree () # ~ <Method> # Print tree of Id info of current class and all super-types
{
  class.info
  test -z "${super:-}" ||
    $super$1 | sed 's/^/  /'
}


# The abstract base class with some helpers.
# This keeps the concrete type and constructor params in a global array, the
# instance Id being used as index key.

class.Class.load () #
{
  # Assoc-array to store 'params': arguments passed into Class constructor
  declare -g -A Class__instances=()
}

class.Class () # ~ <Instance-Id> .<Message-name> <Args...>
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
  test $# -gt 0 || return 177
  test $# -gt 1 || set -- "$1" .default
  local name=Class self="class.Class $1 " super_type=root super id=${1:?} m=$2
  shift 2

  case "$m" in

    # 'Constructor' just stores arguments in array. By convention the first
    # word should indicate the concrete type for the Id.
    ".$name" )
        test -n "${1:-}" ||
            $LOG error : "Concrete type expected" "" 1 || return
        Class__instances[$id]="$*" ;;
    # 'Destructor'
    ".__$name" )
        : "${Class__instances[$id]:?Expected class instance #$id}"
        unset "Class__instances[$id]" ;;

    .id ) echo "$id" ;;
    .defined ) test -n "${Class__instances[$id]:-}" ;;
    .class )
        : "${Class__instances[$id]:?Expected class instance #$id}"
        echo "${_/ *}" ;;
    .params )
        : "${Class__instances[$id]:?Expected class instance #$id}"
        if_ok "$($self.class)" || return
        : "$(( ${#_} + 1 ))"
        echo "${Class__instances[$id]:$_}" ;;

    # XXX: maybe/prolly want to split-off .context to something that iter's ID/types
    .tree|.context ) class.info-tree ;;
    .toString | \
    .default | \
    .info ) class.info ;;

    * )
        $LOG error "" "No such endpoint '$m' on" "$($self.info)" 1
      ;;
  esac
}

#
