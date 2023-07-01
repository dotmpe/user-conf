# Looking at a method to work with either dynamic or static metadata

# Only using variables, nother other AST currently for metadata.

# This provides uc-fields-define to create global associative arrays with
# name pattern {base}_{group}_{field} which normally corresponds to
# uc_fields_{field_name} here.

# Functions uc-field{,-{hook,update,varname,define}} are used to access/set
# values and run hook routines for defined fields. In particular uc-field-update
# checks for and invokes {base}_{group}_{field}_update.
# XXX: hook_require is not set to true, could be required?

# A variant on uc-field, uc-vfield adds validation to the value before it is
# stored, but it cannot be used as getter like uc-field.

# The initial function set is used as basis for uc-cmdcache.lib


uc_fields_lib__load ()
{
  lib_require str-uc shell-uc uc || return

  : "${uc_fields_default_validator:=change}"
}

#uc_fields_lib__init ()
#{
#  test -z "${uc_fields_lib_init:-}" || return $_
#}


# Simple get/set'er for field. To check the value before storing use uc-vfield.
uc_field () # [base] ~ <Name> <Key> [<Value>]
{
  local field=${1:?} key=${2:?} newval=${3:-} varn base=${base:-uc} stat
  uc_field_varname || return
  test 2 -eq $# && {
    # Respond with current value
    ${uc_field_required:-false} &&
      echo "${!varn}" ||
      echo "${!varn:-}"
  } || {
    # Set new value in field array for key
    # XXX: Don't know any other way to do this (for a global Array) than to use eval
    eval "$varn=\"$newval\""
    # Not sure if status matters really?
    stat=$?
    "${quiet:-false}" && return $stat ||
      ! uc_fields_debug "$stat" && return $stat ||
        $LOG debug :$base-field "Updated value" "$field:$key:E$stat" $stat
  }
}

# Invoke named hook function for field/group. This does not touch/fetch field
# values in any way, but does invoke a function name using the same name format
# as the uc-fields array variables.
uc_field_hook () # [base,hook{,-{group,require}}] ~ <Name> <Hook-arg...>
{
  local field=${1//-/_} group funn base=${base:-uc} hook=${hook:-update}
  group=${hook_group:+${hook_group//-/_}}
  : "${group:=fields}"
  funn=${base}_${group}_${field}_${hook}
  sh_fun "$funn" || {
    ${hook_require:-false} && return 1 || return 0
  }
  "$funn" "${@:2}"
}

uc_field_hooks () # ~ <uc-field-hook-args...>
{
  local _base
  for _base in $(uc_bases)
  do
    base=$_base uc_field_hook "$@" || return
  done
}

# A wrapper for setter operations, this calls the 'update' hook if defined for
# field after the setter run succesfully.
uc_field_update () # (base) ~ <Name> <Key> <Newval>
{
  local name=${1:?} key=${2:?} newval=${3:?} varn base=${base:-uc}
  field=$name uc_field_varname || return
  uc_field "$@" && hook=update uc_field_hook "$name" "$key"
}

# Helper to fill out varn variable with name of array and index if key is
# defined.
uc_field_varname () # (base,field) [key] <varn> ~
{
  varn="${base}_fields_${field//-/_}"
  ${quiet:-false} || ! uc_fields_debug || sh_arr $varn ||
      $LOG error : "No such array" "$varn:E$?" $? || return
  test -z "${key:-}" || varn="${varn}[$key]"
}

uc_fields_debug () # ~ <->
{
  ${UC_FIELDS_DEBUG:-${UC_DEBUG:-${DEBUG:-false}}}
}

# Define global associative arrays for fields, to use for caching
uc_fields_define () # [field-group] ~ <Base> <Braces-exprs...|Field-names...>
{
  local base=${1:?} group=${field_group:-fields}
  shift
  test $# -gt 0 || return ${_E_GAE:-193}
  local field_name
  while test $# -gt 0
  do
    test "${1:0:1}" = "{" && {
      set -- $(str_sh_expand_braces $1) "${@:2}"
    }
    field_name=${1:?}
    declare -gA ${base}_${group}_${field_name//-/_}
    shift
  done
}

# A wrapper for the uc-field set'er that runs validators on new value for
# given field before. Because both field variable names and hooks depend on
# <base>, the current base is used to set <varn>, but during loop/hook <base>
# will be whatever the hook is from.
uc_vfield () # [base] ~ <Name> <Key> [<Value>]
{
  local field=${1:?} key=${2:?} varn newval=${3:-} _base base=${base:-uc} \
    hook=validate hook_group=vfield \
    vvdtors=${uc_fields_validator:-${uc_fields_default_validator:?}}
  uc_field_varname || return
  for vvdtor in ${vvdtors//,/ }
  do
    uc_field_hooks "$vvdtor" "$field" "$key" "$newval" || return
  done
  uc_field "$@"
}

# Fails unless value actually changed, returns E:next if values are identical.
uc_vfield_change_validate () # ~ <Name> <Key> <Value>
{
  local field=${1:?} key=${2:?} newval=${3:-} varn base=${base:-uc}
  test "${newval}" != "${!varn:-}" || return ${_E_next:-196}
}

#
