#!/bin/sh

shell_uc_lib_load ()
{
  # SHELL can be deceiving and although it should be set correctly, we check
  # the type of specific commands

  # XXX:
  SHELL_NAME=$(basename -- "$SHELL")
  sh_init_mode # && sh_env_init
}

sh_init_mode ()
{
  IS_BASH_SH=0
  IS_DASH_SH=0
  IS_BB_SH=0
  IS_HEIR_SH=0
  #test "$SHELL_NAME" != "sh" || {
    shell_detect_sh
  #}
}

# Try to detect Shell variant based on specific commands.
# See <doc/shell-builtins.tab>
shell_detect_sh ()
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

# Test true if CMD is a builtin command
sh_is_type_bi() # CMD
{
  type "$1" | grep -q '^'"$1"' is a shell builtin$'
}

# Test true if CMD is a special builtin command
sh_is_type_sbi() # CMD
{
  type "$1" | grep -q '^[^ ]* is a special shell builtin$'
}

# Test true if CMD resolves to an executable at path
sh_is_type_bin() # CMD
{
  type "$1" | grep -q '^[^ ]* is /[^ ]*$'
}

#
