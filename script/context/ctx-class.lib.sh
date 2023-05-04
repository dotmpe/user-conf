#!/usr/bin/env bash
# Created: 2020-09-16

ctx_class_lib__load ()
{
  : "${ctx_class_types:="${ctx_class_types-}${ctx_class_types+" "}Class"}"
}

ctx_class_lib__init ()
{
  create() { class.init "$@"; }
  for class in $ctx_class_types
  do sh_fun class.$class.load || continue
    class.$class.load
  done
}

ctx_class_info ()
{
  echo "class.$name <#$id> ${Class__instances[$id]}"
}

# The 'new' handler. Initialize a new instance of Type.
class.init () # ~ <Target-Var> <Type> <Constructor-Args...>
{
  test $# -ge 1 || return 177
  local id=$RANDOM var=$1 type=$2 ; shift 2

  # XXX: at some point, should check wether $id is already used
  local new="class.$type $id "

  # Call constructor(s)
  $new.$type "$@"

  declare -g $var="$new"
}

class.Class.load () #
{
  # To store arguments passed up to Class constructor
  declare -g -A Class__instances=()
}

class.Class () # Instance-Id Message-Name Arguments...
{
  test $# -gt 0 || return 177
  test $# -gt 1 || set -- $1 .default
  local name=Class self="class.Class $1 " id=$1 m=$2
  shift 2

  case "$m" in

    # 'Constructor' just stores arguments in array
    .$name ) Class__instances[$id]="$*" ;;
    # 'Destructor'
    .__$name ) unset Class__instances[$id] ;;

    .id ) echo "$id" ;;

    .toString | \
    .default | \
    .info ) ctx_class_info ;;

    * )
        $LOG error "" "No such endpoint '$m' on" "$($self.info)" 1
      ;;
  esac
}

#
