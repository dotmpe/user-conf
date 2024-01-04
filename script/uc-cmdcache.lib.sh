# The 'commands' field holds a multiline string where each line is used
# as argument ie. element of a command line. The other fields are
# descriptors for this array. commands-time is the moment after the command
# completed and stdout and status was captured. ttl allows a per-command key
# time-to-live value.

uc_cmdcache_lib__load ()
{
  lib_require uc-fields || return
  : "${uc_cache_default_validator:=ttl}"
  : "${uc_fields_default_ttl:=300}" # Five minutes
}

uc_cmdcache_lib__init ()
{
  test -z "${uc_cmdcache_lib_init-}" || return $_
  uc_fields_define uc commands-{{start-,}time,ttl,status,stdout} &&
  uc_fields_group_define uc commands
}


#
uc_cache_ttl_validate () # [base,field] ~ <Key>
{
  local last_time TTL ltime_varn ttl_varn
  ltime_varn=${base:-uc}_fields_${field//-/_}_time[$1]
  last_time=${!ltime_varn:--1}
  ttl_varn=${base:-uc}_fields_${field//-/_}_ttl[$1]
  TTL=${!ttl_varn:-${uc_fields_default_ttl:?}}
  : "$(date +%s)"
  test $(( _ - last_time )) -le $TTL
}

# Helper to select validator function.
uc_cache_validate () # [base] (field) ~ <Key>
{
  local base=${base:-uc} group=cache field hook=validate
  field=${uc_fields_default_validator}
  hook_require=true uc_field_hook "$field" "${1:?}"
}

# Helper to write command line and arguments as lines to uc-field
uc_command () # ~ <Key> <Command-args...>
{
  uc_field_update commands "${1:?}" "$(printf '%s\n' "${@:2}")"
}

# Helper to call uc-cache and uc-command functions: re-run command if cache is OOD
uc_command_cache () # ~ <key>
{
  field=commands uc_cache_validate "$1" || uc_command_run "$@"
}

# Execute command and keep completion time, status and stdout. If value did
# not change return 0 without updating. This uses the uc-command-* array
# variables defined with uc-fields to lookup command lines by key, but also
# to store the output results in several fields for that same command Id key.
# To track multiple outputs, a custom key can be provided.
uc_command_run () # [base,field] ~ <key> [<cache-key>]
{
  local status stdout varn base=${base:-uc} field=${field:-commands} time ckey
  ckey=${2:-${1:?}}
  varn="${base}_fields_${field//-/_}[${1:?}]"
  mapfile -t cmdline <<< "${!varn}"
  ${quiet:-false} ||
      $LOG info : "Running" "${cmdline[*]@Q}"
  stdout=$("${cmdline[@]}")
  status=$?
  time=$(date +%s)
  uc_vfield $field-stdout "$ckey" "$stdout" || {
    test ${_E_next:-196} -eq $? && {
      $LOG notice : "No value change" "$field-stdout" && return
    } || return $_
  }
  uc_field $field-status "$ckey" "$status" &&
  uc_field $field-time "$ckey" "$time" &&
  return $status
}

# Update hook for commands field resets time/status/output of previous command.
# XXX: actually unset keys?
uc_fields_commands_update () # ~ (base,field) ~ <Key>
{
  uc_field ${field:?}-time "${1:?}" "" &&
  uc_field ${field:?}-status "$1" "" &&
  uc_field ${field:?}-stdout "$1" ""
}

# XXX: record start time as well if command was OK
uc_timed_run () # [base,field] ~ <Key>
{
  local time=$(date +%s)
  uc_command_run "$@" || return
  uc_field $field-start-time "${1:?}" "$time"
}

#
