#!/bin/sh

### A minimal shell sh-env-init


shell_uc_lib_load ()
{
  true
}

shell_uc_lib_init ()
{
  # Fix SHELL setting.

  # The problem is Bash, it seems /bin/sh mode in particular.
  # I want to restore an empty value using either PID_CMD or ENV_CMD.

  # Both should be the same and as $0 as well for an (interactive) login shell.
  # But in a script execution context there is no ENV_CMD, PID_CMD will be
  # whatever the shebang started, and zeroth will be the script name.

  # Different command invocations may give rise to peculiarities as well.
  # If not interactive, the process MAY be replaced by the command;
  # but only in case of simple commands. For example pipelines or subshell
  # expressions will make the shell remain the parent process.
  # Observed with Bash.

  # Get the command path of the current PID
  PID_CMD=$(ps -q $$ -o command= | cut -d ' ' -f 1)

  test -n "${SHELL:-}" || {
    test -n "${ENV_CMD:-}" && {
      test "$ENV_CMD" = "$PID_CMD" -a "$ENV_CMD" = "$0" && {
          test "${ENV_CMD:0:1}" = "-" &&
            SHELL_NAME=${ENV_CMD:1} ||
            SHELL_NAME=$(basename -- "$ENV_CMD")
        } || true
    } || {
      SHELL_NAME=$PID_CMD
    }
  }

  true "${SHELL:="$(command -v "$SHELL_NAME")"}"
  true "${SHELL_NAME:="$(basename -- "$SHELL")"}"

  ! ${shell_uc_debug:-false} || {
    {
      echo shell_uc_lib_init
      declare -p SHELL SHELL_NAME PID_CMD ENV_CMD CMD_ARG
      echo "$(tty) $\$: $$ 0: '$0' *: '$*'"
      echo
    } >&2
  }

  # XXX: Bash exports SHELL, dont like that. But its not easy to unset. I
  # a similar line at the top of /etc/profile
  test "$SHELL_NAME" = "bash" && {
    declare +x SHELL=$SHELL
    # Still, when unexported, /bin/sh mode bash still manages to get this setting.
    # Unless we clear it like SHELL= /bin/sh only then it is empty as expected.
  }

  #shell_uc_init
  test -z "${BASH_VERSION:-}" && IS_BASH=0 || IS_BASH=1
  shell_uc_def
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

    shell_uc_detect_sh || {
      #${INIT_LOG:?} warn "" "Detect failed" ""
      echo "Detect failed" >&2
      #return
    }

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

    sh_als() # Is name of shell alias # sh:no-stat
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

    # Return false unless the given number is an understood exit-status code.
    sh_status ()
    {
      test $1 -eq 1 \
        -o $1 -eq 2 \
        -o $1 -eq 126 \
        -o $1 -eq 127 \
        -o \( $1 -ge 128 -a $1 -le 192 \) \
        -o $1 -eq 255
    }

    # Print a short description for a given exit-status code.
    # Obviously this is not a standard but mostly shell (Bash) specific.
    # E.g. many programs will use 2 with
    # other meanings than 'illegal argument/syntax error'.
    sh_state_name ()
    {
      # Generic not-okay status
      test $1 -eq 1 && echo Failed
      # Incomplete statements, missing or illegal arguments (shell)
      test $1 -eq 2 && echo Syntax Error
      # Problem executing command-name (or no permissions)
      test $1 -eq 126 && echo Not Executable
      # No such command name
      test $1 -eq 127 && echo Not Found

      # An entire block starting at 128 is used for when programs return because
      # of an (unhandled or servicable) signal.
      # On my Debian Linux 5.4 kernel, kill -l accepts 0-64 values. Making this
      # block end at 192. Although I doubt many of those will ever be seen as
      # an actual exit status code, some often are, like INT, KILL and PIPE.
      test \( $1 -ge 128 -a $1 -le 192 \) && {
        echo SIG:$(kill -l $(( $1 - 128 )))
      }

      # It was claimed online that somewhere a 0 > status > 256 would be set to
      # 255, but I have not seen Bash do this. And in fact using out-of-range
      # integers in shell scripts yields very strange results. Non-integers
      # will just make shell exit return 2.
      # Still, leaving this in here.
      test $1 -eq 255 && echo Out of Range
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

    sh_als() # Is name of shell alias # sh:no-stat
    {
      sh_is_type_als "$1"
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
    sh_als "$1" && return
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
sh_is_type_als () # ~ <Name>
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
