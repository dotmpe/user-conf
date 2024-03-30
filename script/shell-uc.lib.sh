#!/usr/bin/env bash

### A minimal shell sh-env-init


shell_uc_lib__load ()
{
  if_ok () { return; }
}

shell_uc_lib__init ()
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

  # Get the path to executable of the current PID (ie. not the same as 'comm')
  PID_CMD=$(ps -q $$ -o command= | cut -d ' ' -f 1) || return

  [[ "${SHELL-}" ]] || {
    [[ "${ENV_CMD-}" ]] && {
      [[ "$ENV_CMD" = "$PID_CMD" && "$ENV_CMD" = "$0" ]] && {
          [[ "${ENV_CMD:0:1}" = "-" ]] &&
            SHELL_NAME=${ENV_CMD:1} ||
            SHELL_NAME=$(basename -- "$ENV_CMD")
        } || true
    } || {
      SHELL_NAME=$PID_CMD
    }
  }

  if_ok "${SHELL:="$(command -v -- "$SHELL_NAME")"}" &&
  if_ok "${SHELL_NAME:="$(basename -- "$SHELL")"}" || return

  ! ${shell_uc_debug:-false} || {
    {
      echo shell_uc_lib__init
      declare -p SHELL SHELL_NAME PID_CMD ENV_CMD CMD_ARG
      echo "$(tty) $\$: $$ 0: '$0' *: '$*'"
      echo
    } >&2
  }

  # XXX: Bash exports SHELL, dont like that. But its not easy to unset.
  [[ "$SHELL_NAME" = "bash" ]] && {
    declare +x SHELL=$SHELL
    # when unexported, /bin/sh mode bash still manages to get this setting.
    # Unless we clear it like SHELL= /bin/sh, only then it stays empty as expected.
  }

  [[ -x "$SHELL" ]] || {
    $LOG warn "" "Expected executable for current shell" "$SHELL"
  }

  #shell_uc_init
  [[ -z "${BASH_VERSION:-}" ]] && IS_BASH=0 || IS_BASH=1
  shell_uc_def
}

shell_uc_init ()
{
  [[ "$SHELL_NAME" = "bash" ]] && BA_SHELL=1 || BA_SHELL=0
  [[ "$SHELL_NAME" = "zsh" ]] && Z_SHELL=1 || Z_SHELL=0
  [[ "$SHELL_NAME" = "ksh" ]] && KORN_SHELL=1 || KORN_SHELL=0
  [[ "$SHELL_NAME" = "dash" ]] && D_A_SHELL=1 || D_A_SHELL=0
  [[ "$SHELL_NAME" = "ash" ]] && A_SHELL=1 || A_SHELL=0
  [[ "$SHELL_NAME" = "sh" ]] && B_SHELL=1 || B_SHELL=0

  IS_BASH_SH=0
  IS_DASH_SH=0
  IS_BB_SH=0 # 'Busybox'
  IS_HEIR_SH=0

  [[ $B_SHELL = 1 ]] && {

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
  [[ $IS_BASH -eq 1 ]] && {

    sh_als () # Is name of shell alias # sh:no-stat
    {
      [[ "$(type -t "$1")" = "alias" ]]
    }

    sh_als_cmd ()
    {
      type "${1:?}" | {
        read -r cmdline
        cmdline=${cmdline/*\`}
        len=$(( ${#cmdline} - 1 ))
        echo "${cmdline:0:$len}"
      }
    }

    sh_aarr ()
    {
      sh_vfl "A" "$1"
    }

    sh_arr ()
    {
      sh_vfl "a" "$1" || sh_vfl "A" "$1"
    }

    sh_bi()
    {
      [[ "$(type -t "$1")" = "builtin" ]]
    }

    sh_env () # List all variable names, exported or not # sh:no-stat
    {
      [[ $# -eq 0 ]] && {
        {
          set | grep '^[_A-Za-z][A-Za-z0-9_]*=.*$' && env
        } | awk '!a[$0]++'
        return
      }

      sh_env | grep ${grep_f:-"-E"} "^$1="
    }

    sh_fun () # Is name of shell funtion # sh:no-stat
    {
      [[ "$(type -t "$1")" = "function" ]]
    }

    sh_iarr ()
    {
      sh_vfl "a" "$1"
    }

    sh_isset() # Variable is declared (set or unset) # sh:no-stat
    {
      [[ "${!1+set}" ]]
      #if_ok "$(declare -p "${1:?}")"
      #grep_f=-qE sh_env "$1"
    }

    sh_kw()
    {
      [[ "$(type -t "$1")" = "keyword" ]]
    }

    # Return false unless the given number is an understood exit-status code.
    sh_status ()
    {
      [[ $1 -gt 0 && $1 -le 3 \
        || $1 -eq 126 \
        || $1 -eq 127 \
        || ( $1 -ge 128 && $1 -le 192 ) \
        || $1 -eq 255 ]]
    }

    # Print a short description for a given exit-status code.
    # XXX: should tie this to some context, ie. this is mostly Bash and shell
    # specific. E.g. grep has other status meanings, and so do other programs
    # for status 2, etc.
    sh_state_name ()
    {
      # E:fail Generic failed (ie. status for FALSE), or any error if further
      # unspecified
      [[ $1 -eq 1 ]] && echo Failed
      # E:script Incomplete statements, missing or illegal arguments (shell)
      [[ $1 -eq 2 ]] && echo Script Error
      # E:user Unexpected or incorrect environment, user data or script
      # parameters (usage)
      [[ $1 -eq 3 ]] && echo User Error

      # E:exec: Problem executing command-name (or no permissions)
      [[ $1 -eq 126 ]] && echo Not Executable
      # E:nsf: No such file or command name
      [[ $1 -eq 127 ]] && echo Not Found

      # An entire block starting at 128 is used for when programs return because
      # of an (unhandled or servicable) signal.
      # On my Debian Linux 5.4 kernel, kill -l accepts 0-64 values. Making this
      # block end at 192. Although I doubt many of those will ever be seen as
      # an actual exit status code, some often are, like INT, KILL and PIPE.
      [[ $1 -ge 128 && $1 -le 192 ]] && {
        echo SIG:$(kill -l $(( $1 - 128 )))
      }

      # It was claimed online somewhere that an 0 > status > 256 would change
      # to 255, but I have not seen Bash do this. XXX: And in fact using out-of-range
      # integers in shell scripts yields very strange results. Non-integers
      # will just make shell exit return 2.
      # Still, leaving this in here.
      [[ $1 -eq 255 ]] && echo Out of Range
    }

    sh_type () { type "$@"; }

    sh_var ()
    {
      declare -p "${1:?}" >/dev/null 2>&1
    }

    # Shell/variable-flag-match matches if any of given flags is set
    sh_vfl () # ~ <Flags> <Var>
    {
      : about 'Shell :variable-flags-match'
      : group 'Shell'
      : group 'core'

      declare flags var
      flags=${1:?"$(sys_exc compo.inc:sh-core:sh-vfl:flags Expected)"}
      var=${2:?"$(sys_exc compo.inc:sh-core:sh-vfl:var Expected)"}
      # XXX: Can't make string-expression syntax work for dynamic variable names,
      #case "${!var[@]@A}" in ( -*[Aa]* ) true ;; ( * ) false ;; esac
      # so need to use declare -p invocation instead
      decl="$(declare -p $var 2>/dev/null)" &&
      case "$decl" in ( "declare -$flags $var"* ) ;; * ) false; esac
    }

    sh_vfls ()
    {
      var=${1:?"$(sys_exc compo.inc:sh-core:sh-vfls:var Expected)"}
      if_ok "$(declare -p $var 2>/dev/null)" &&
      : "${_#declare -}" &&
      : "${_% $var*}" &&
      echo "$_"
    }

  } || {

    sh_env() # sh:no-stat
    {
      set
    }

    sh_isset() # sh:no-stat
    {
      sh_env | grep -qi '^'$1=
    }

    sh_fun () # Is name of shell funtion # sh:no-stat
    {
      sh_is_type_fun  "$1"
    }

    sh_als () # Is name of shell alias # sh:no-stat
    {
      sh_is_type_als "$1"
    }

    sh_als_cmd()
    {
      false
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

  sh_unals_if ()
  {
    sh_als "${1:?}" || return 0
    unalias "$1"
  }

  sh_cmd ()
  {
    command -v "${1:?}" >/dev/null
  }

  sh_exported() # List all exported env # sh:no-stat
  {
    [[ $# -eq 0 ]] && {
      env
      return
    }

    sh_exported | grep ${grep_f:-"-qE"} "^$1="
  }

  sh_exe () # Is user callable
  {
    local type="$( type -t "$1" )";
    [[ "$type" = "function" ]] && return;
    [[ "$type" = "file" && -x "$(command -v "$1")" ]] && return;
    {
      [[ "$type" = "alias" ]] && shopt -q expand_aliases &&
        eval "sh_cmd $(sh_quote=true sh_als_cmd "$1")"
    } && return
  }

  sh_source ()
  {
    . "${1:?}"
  }

  # TODO: replace uc_source etc. Change sh_source to one tracking includes
  # but for in certain shells only.
  sh_source=sh_source

  sh_lookup ()
  {
    false
  }

  sh_include ()
  {
    local r
    sh_lookup "${1:?}"

    sh_source "${1:?}"
    r=$?
    declare -g -- sh_include_$(echo "$1" | tr -c 'A-Za-z0-9_' '_' )=$r
    return $r
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
