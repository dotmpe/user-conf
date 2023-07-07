#!/bin/bash


# Add fallbacks for non-std BATS functions

#. "${US_BIN:-$HOME/bin}/script-mpe.lib.sh"

# XXX: conflicts with ztombl assert's lib
type fail >/dev/null 2>&1 || {
  fail()
  {
    test -n "$1" && echo "Reason: $1" >>"$BATS_OUT"
    exit 1
  }
}

type diag >/dev/null 2>&1 || {
  # Note: without failing test, output will not show up in std Bats install
  diag()
  {
    #BATS_TEST_DIAGNOSTICS=1
    #echo "$1" >>"$BATS_OUT"
    # XXX: since Bats 1.2.0?
    echo "# $1" >>"$BATS_OUT"
  }
}

type TODO >/dev/null 2>&1 || { # tasks:no-check
  TODO() # tasks:no-check
  {
    test -n "${TODO_IS_FAILURE-}" && {
      {
        test -z "$1" &&
          "TODO ($BATS_TEST_DESCRIPTION)" || echo "TODO: $1"  # tasks:no-check
      }>>"$BATS_OUT"
      exit 1
    } || {
      # Treat as skip
      skip "TODO: $BATS_TEST_DESCRIPTION"
      #BATS_TEST_TODO=${1:-1}
      #BATS_TEST_COMPLETED=1
      #exit 0
    }
  }
}

type stdfail >/dev/null 2>&1 || {
  stdfail()
  {
    test -n "$1" || set -- "Unexpected. Status"
    diag "$1: E$status, output(${#lines[@]}) was:"
    printf "  %s\n" "${lines[@]}" >>"$BATS_OUT"
    exit 1
  }
}

type pass >/dev/null 2>&1 || {
  pass() # a noop() variant..
  {
    return 0
  }
}

type test_ok_empty >/dev/null 2>&1 || {
  test_ok_empty()
  {
    test ${status} -eq 0 && test -z "${lines[*]}"
  }
}

type test_nok_empty >/dev/null 2>&1 || {
  test_nok_empty()
  {
    test ${status} -ne 0 && test -z "${lines[*]}"
  }
}

type test_nonempty >/dev/null 2>&1 || {
  test_nonempty()
  {
    test -n "${lines[*]}" || return $?
    for match in "$@"
    do
        case "$match" in

          # Test line-count if number given.
          # NOTE BATS 0.4 strips empty lines! not blank lines.
          # As wel as combining stdout/err
          [0-9]|[0-9][0-9]|[0-9][0-9][0-9] )
            test "${#lines[*]}" = "$1"  || return $? ;;

          # Each match applies to entire line list otherwise
          * ) fnmatch "$1" "${lines[*]}" || return $? ;;

        esac
    done
  }
}

type test_ok_nonempty >/dev/null 2>&1 || {
  test_ok_nonempty()
  {
    test ${status} -eq 0 && test -n "${lines[*]}" && {
      test -n "$*" || return 0
      test_nonempty "$@"
    }
  }
}

type test_nok_nonempty >/dev/null 2>&1 || {
  test_nok_nonempty()
  {
    test ${status} -ne 0 && test -n "${lines[*]}" && {
      test -n "$*" || return 0
      test_nonempty "$@"
    }
  }
}

type test_lines >/dev/null 2>&1 || {
  test_lines()
  {
    # Each match must be present on a line (given arg order is not significant)
    for match in "$@"
    do
      local v=1 ; for line in "${lines[@]}"
      do
        fnmatch "$match" "$line" && { v=0; break; }
        continue
      done
      test $v -eq 0 || {
        diag "Unmatched '$match'"
        return $v
      }
    done
  }
}

type test_ok_lines >/dev/null 2>&1 || {
  test_ok_lines()
  {
    test -n "${lines[*]}" || return
    test -n "$*" || return
    test ${status} -eq 0 || return
    test_lines "$@"
  }
}

type test_nok_lines >/dev/null 2>&1 || {
  test_nok_lines()
  {
    test ${status} -ne 0 && test -n "${lines[*]}" && {
      test -n "$*" || return $?
      test_lines "$@"
    }
  }
}

# Set env and other per-specfile init
test_init()
{
  test -n "$uname" || uname=$(uname)
  hostname_init
}

hostname_init()
{
  hostnameid="$(hostname -s | tr 'A-Z.-' 'a-z__')"
}

init_bin()
{
  test_init
#  test -z "$PREFIX" && bin=$base || bin=$PREFIX/bin/$base
}

init_lib()
{
  test_init || return
  # XXX path to shared script files
  test -z "$PROJ_DIR" && lib=./script || lib=$PROJ_DIR/script
}

init()
{
  # Load envs
  source "./test/envs.sh" || error "Loading envs.sh" 1
  # Setup test-case vars
  test -x $base && {
    init_bin
  }
  init_lib || return
  uc_lib=$lib/user-conf
  UC_LIB_PATH=$lib
  : "${LOG:=${U_C:?}/tools/sh/log.sh}"
}


### Helpers for conditional tests
# currently usage is to mark test as skipped or 'TODO' per test case, based on
# host. Written into the specs itself.

# Returns successful if given key is not marked as skipped in the env
# Specifically return 1 for not-skipped, unless $1_SKIP evaluates to non-empty.
is_skipped()
{
  local key=$(echo "$1" | tr 'a-z-.' 'A-Z__')
  local skipped=$(echo $(eval echo \$${key}_SKIP))
  test -n "$skipped" && return
  return 1
}

current_test_env()
{
  test -n "$TEST_ENV" && { echo $TEST_ENV ; return; }
  test -n "$hostnameid" || hostname_init
  test -n "$test_env_hosts" && {
    case " $test_env_hosts " in
      *" $hostnameid "* ) echo $hostnameid ; return ;;
    esac
  }
  test -n "$test_env_user_hosts" && {
    case " $test_env_user_hosts " in
      *" $hostnameid "* ) whoami ; return ;;
    esac
  }
  test -n "$test_env_other" &&
    echo $test_env_other ||
    echo "$(whoami)-$hostnameid"
}

# Check if test is skipped. Currently works based on hostname and above values.
check_skipped_envs()
{
  local cur_env=$(current_test_env)
  while test -n "$1"
  do
    test "$1" = "$cur_env" && return 1
    shift
  done
}

### Misc. helper functions

next_temp_file()
{
  test -n "$pref" || pref=script-mpe-test-
  local cnt=$(echo $(echo /tmp/${pref}* | wc -l) | cut -d ' ' -f 1)
  next_temp_file=/tmp/$pref$cnt
}

lines_to_file()
{
  # XXX: cleanup
  echo "status=${status}"
  echo "#lines=${#lines[@]}"
  echo "lines=${lines[*]}"
  test -n "$1" && file=$1
  test -n "$file" || { next_temp_file; file=$next_temp_file; }
  echo file=$file
  local line_out
  echo "# test/helper.bash $(date)" > $file
  for line_out in "${lines[@]}"
  do
    echo $line_out >> $file
  done
}

tmpf()
{
  tmpd || return $?
  tmpf=$tmpd/$BATS_TEST_NAME-$BATS_TEST_NUMBER
  test -z "$1" || tmpf="$tmpf-$1"
}

tmpd()
{
  tmpd=$BATS_TMPDIR/bats-tempd
  test -d "$tmpd" && rm -rf $tmpd
  mkdir -vp $tmpd
}

# Id: U-c:test/helper.bash
