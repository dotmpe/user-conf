#!/bin/sh

### A minimal shell sh-env-init


shell_uc_lib_load ()
{
  SHELL_NAME="$(basename -- "${SHELL?}")"  || return

  shell_uc_init
}

shell_uc_init ()
{
  test "$SHELL_NAME" = "bash" && BA_SHELL=1 || BA_SHELL=0
  test "$SHELL_NAME" = "zsh" && Z_SHELL=1 || Z_SHELL=0
  test "$SHELL_NAME" = "ksh" && KORN_SHELL=1 || KORN_SHELL=0
  test "$SHELL_NAME" = "dash" && D_A_SHELL=1 || D_A_SHELL=0
  test "$SHELL_NAME" = "ash" && A_SHELL=1 || A_SHELL=0
  test "$SHELL_NAME" = "sh" && B_SHELL=1 || B_SHELL=0

  IS_BASH_SH=0
  IS_DASH_SH=0
  IS_BB_SH=0
  IS_HEIR_SH=0

  test $B_SHELL = 1 && {

    shell_uc_detect_sh

    IS_BASH=$IS_BASH_SH
    IS_DASH=$IS_DASH_SH
  } || {

    IS_BASH=$BA_SHELL
  }

  shell_uc_def
}

shell_uc_detect_sh ()
{
  sh_is_type_bi 'bind' && IS_BASH_SH=1 || {

    sh_is_type_sbi 'local' && {
      # XXX: what was 'BB' again?
      sh_is_type_bi 'let' && IS_BB_SH=1 || IS_DASH_SH=1

    } || {
      sh_is_type_bin 'false' &&
        # Assume heirloom shell
        IS_HEIR_SH=1 || false # unknown Sh
    }
  }
}

shell_uc_def ()
{
  test $IS_BASH -eq 1 && {

    sh_env () # List all variable names, exported or not # sh:no-stat
    {
      test $# -eq 0 && {
        {
          set | grep '^[_A-Za-z][A-Za-z0-9_]*=.*$' && env
        } | awk '!a[$0]++'
        return
      }

      sh_env | grep ${grep_f:-"-E"} "^$1="
    }

    sh_isset() # Variable is set, even if empty # sh:no-stat
    {
      grep_f=-qE sh_env "$1"
    }

    sh_fun() # Is name of shell funtion # sh:no-stat
    {
      test "$(type -t "$1")" = "function"
    }

    sh_a() # Is name of shell alias # sh:no-stat
    {
      test "$(type -t "$1")" = "alias"
    }

    sh_bi()
    {
      test "$(type -t "$1")" = "builtin"
    }

    sh_kw()
    {
      test "$(type -t "$1")" = "keyword"
    }

    sh_status ()
    {
      test $1 -eq 1 \
        -o $1 -eq 2 \
        -o $1 -eq 126 \
        -o $1 -eq 127 \
        -o \( $1 -ge 128 -a $1 -le 157 \)
        #-o $1 -eq 255
    }

    sh_state_name ()
    {
      test $1 -eq 1 && echo Failed
      test $1 -eq 2 && echo Syntax Error
      test $1 -eq 126 && echo Not Executable
      test $1 -eq 127 && echo Not Found
      test \( $1 -ge 128 -a $1 -le 157 \) && {
        echo SIG:$(kill -l $(( $1 - 128 )))
      }
      # Never bash produce this with illegal exit codes
      #test $1 -eq 255 && echo Exit out of range
    }

    sh_type () { type "$@"; }

  } || {

    sh_env() # sh:no-stat
    {
      set
    }

    sh_isset() # sh:no-stat
    {
      sh_env | grep -qi '^'$1=
    }

    sh_fun() # Is name of shell funtion # sh:no-stat
    {
      sh_is_type_fun  "$1"
    }

    sh_a() # Is name of shell alias # sh:no-stat
    {
      sh_is_type_a "$1"
    }

    sh_bi()
    {
      sh_is_type_bi "$1" ||
      sh_is_type_sbi "$1"
    }

    sh_kw()
    {
      sh_is_type_kw "$1"
    }

    sh_status () { false; }

    sh_type () { type "$@" 2>/dev/null; }
  }

  sh_type=sh_type

  sh_cmd()
  {
    sh_exe "$1" && return
    sh_fun "$1" && return
    sh_a "$1" && return
    sh_bi "$1" && return
    sh_kw "$1"
  }

  sh_exported() # List all exported env # sh:no-stat
  {
    test $# -eq 0 && {
      env
      return
    }

    sh_exported | grep ${grep_f:-"-qE"} "^$1="
  }

  sh_exe() # Is name of executable (file) on PATH # sh:no-stat
  {
    test -x "$(which "$1")"
    # test "$(type -t "$1")" = "file"
  }

  sh_source ()
  {
    . "$1"
  }

  # TODO: replace uc_source etc. Change sh_source to one tracking includes
  # but for in certain shells only.
  sh_source=sh_source

  # TODO: id maker.. need str.lib
  sh_include ()
  {
    local r
    sh_source "$1"
    r=$?
    set sh_include_$(echo "$1" | tr -c 'A-Za-z0-9_' '_' )=$r
  }
}

# Test true if <Name> is a builtin command
sh_is_type_bi () # ~ <Name>
{
  ${sh_type:-type} "$1" | grep -q '^[^ ]* is a shell builtin$'
}

# Test true if <Name> is a special builtin command
sh_is_type_sbi () # ~ <Name>
{
  ${sh_type:-type} "$1" | grep -q '^[^ ]* is a special shell builtin$'
}

# Test true if <Name> is an shell command alias
sh_is_type_a () # ~ <Name>
{
  ${sh_type:-type} "$1" | grep -q '^[^ ]* is \(aliased to\|an alias for\) .*$'
}

# Test true if <Name> is a function
sh_is_type_fun () # ~ <Name>
{
  ${sh_type:-type} "$1" | grep -q '^[^ ]* is a shell function$'
}

# Test true if <Name> is a keyword
sh_is_type_kw () # ~ <Name>
{
  ${sh_type:-type} "$1" | grep -q '^[^ ]* is a shell keyword$'
}

# Test true if <Name> resolves to an executable at path
sh_is_type_bin () # ~ <Name>
{
  ${sh_type:-type} "$1" | grep -q '^[^ ]* is /[^ ]*$'
}

# Test true if <Name> is not builtin or executable, or any of the above
sh_is_type_na () # ~ <Name>
{
  ${sh_type:-type} "$1" | grep -q '^.* not found$'
}

#
