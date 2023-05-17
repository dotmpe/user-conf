#!/usr/bin/env bash
# Created: 2020-09-16

ctx_class_lib__load ()
{
  : "${ctx_class_types:="${ctx_class_types-}${ctx_class_types+" "}Class"}"
}

ctx_class_lib__init ()
{
  test -z "${ctx_class_lib_init:-}" || return $ctx_class_lib_init

  create() { class.init "$@"; }
  class.load
}


class.info () # ~ # Print human readable Id info for current class context
{
  echo "class.$name <#$id> ${Class__instances[$id]:?Expected class instance #$id}"
}

class.tree () # ~ <Method> # Print tree of Id info of current class and all super-types
{
  class.info
  test -z "${super:-}" ||
    $super$1 | sed 's/^/  /'
}

# Run load handler of every class that has one, to prepare associative arrays
# for class instance properties
class.load ()
{
  for class in $ctx_class_types
  do sh_fun class.$class.load || continue
    class.$class.load
  done
}

# The 'new' handler. Initialize a new instance of Type, the lib-init hook
# defines 'create' to defer to this.
class.init () # ~ <Target-Var> [<Type>] [<Constructor-Args...>]
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
  declare -g $var="$new_prefix"
}

class.Class.load () #
{
  # Assoc-array to store arguments passed into Class constructor
  declare -g -A Class__instances=()
}

class.Class () # ~ <Instance-Id> .<Message-name> <Args...>
#   .Class <Type> - constructor
{
  test $# -gt 0 || return 177
  test $# -gt 1 || set -- $1 .default
  local name=Class self="class.Class $1 " super_type=root super id=$1 m=$2
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
        : "$($self.class)"
        : "$(( ${#_} + 1 ))"
        echo "${Class__instances[$id]:$_}" ;;

    .tree ) class.tree ;;
    .toString | \
    .default | \
    .info ) class.info ;;

    * )
        $LOG error "" "No such endpoint '$m' on" "$($self.info)" 1
      ;;
  esac
}

#
