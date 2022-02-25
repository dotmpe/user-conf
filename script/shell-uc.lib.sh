#!/bin/sh

### A minimal shell sh-env-init


shell_uc_lib_load ()
{
  sh_env_init
}


sh_env_init ()
{
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

  # XXX: bash type -t
  # because there are no shortcuts for all these tests.

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

  sh_cmd()
  {
    sh_exe "$1" && return
    sh_fun "$1" && return
    sh_a "$1" && return
    sh_bi "$1" && return
    sh_kw "$1"
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

#
