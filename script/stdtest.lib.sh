

# Fail with reason
fail () # ~ REASON [STATUS=E:GE]
{
  # XXX: debug_red "$1"
  error "$1"
  return ${2:-$_E_GE}
}

assert ()
{
  local test="$1"
  shift
  assert_$test "$@"
}

assert_ ()
{
  local test="$1"
  shift
  eval assert_$test "$@"
}

assert_n ()
{
  test -n "$1" || fail "${2:-"Value expected"}"
}

assert_z ()
{
  test -z "$1" || fail "${2:-"Unexpected value"}"
}

assert_eq () # Value-1 Value-2 [Failure-Message] [Faiure-Message-1]
{
  test "$1" = "$2" || fail "${3:-"${4:-"Not equal"}: '$1' != '$2'"}"
}

assert_gt ()
{
  test $1 -gt $2 || fail "${3:-"${4:-"Expected"} greater-than '$2': '$1'"}"
}

assert_lt ()
{
  test $1 -lt $2 || fail "${3:-"${4:-"Expected"} less-than '$2': '$1'"}"
}

assert_ge ()
{
  test $1 -ge $2 || fail "${3:-"${4:-"Expected"} greater-than-or-equal '$2': '$1'"}"
}

assert_le ()
{
  test $1 -lt $2 || fail "${3:-"${4:-"Expected"} less-than-or-equal '$2': '$1'"}"
}

# Verbose test + return status
# Also simple default helper for lookup-path
test_exists() # Local-Name [ Base-Dir ]
{
  test -z "$2" && {
    test -e "$1" || {
      error "No such file or path: $1"
      return 1
    }
  } || {
    test -e "$1/$2" && echo "$1/$2" || return 1
  }
}

assert_d () # ~ Path [Failure-Message]
{
  test -d "$1" || fail "${2:-"No such dir: $1"}"
}

assert_e () # ~ Path [Failure-Message]
{
  test -e "$1" || fail "${2:-"No such path: $1"}"
}

assert_f () # ~ Path [Failure-Message]
{
  test -f "$1" || fail "${2:-"No such file: $1"}"
}

assert_h () # ~ Path [Failure-Message]
{
  test -h "$1" || fail "${2:-"No such symlink: $1"}"
}

#
