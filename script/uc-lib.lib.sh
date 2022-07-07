#!/bin/sh

uc_lib_init()
{
  uc_func lib_load || {
    alias lib_load=uc_lib_load
    alias lib_exists=uc_lib_exists
  }
}

# Load sh-lib on PATH
uc_lib_load()
{
  local f_lib_load= v_lib f_lib_load
  true "${lib_loaded:=}"
  test -n "${__load_lib-}" || local __load_lib=1

  test -n "${1-}" || set -- ${default_sh_lib}
  while test $# -gt 0
  do
    v_lib=$(printf -- "$1" | sed 's/[^A-Za-z0-9_]\{1,\}/_/g')
    test "1" = "$(eval echo \${${v_lib}_lib_loaded-})" && { shift; continue; }

    # XXX: not the same var.. UC_TOOLS_DEBUG?
    test -z "${USER_CONFIG_DEBUG-}" ||
      $LOG info ":uc:lib-load:$1" "Loading" "$v_lib"

    . $1.lib.sh || return
    ENV_SRC="$ENV_SRC$HOME/.conf/script/$1.lib.sh "

    # Evaluate lib-load function
    f_lib_load=${v_lib}_lib_load
    type $f_lib_load >/dev/null 2>&1 && {

      $f_lib_load && eval ${v_lib}_lib_loaded=0 && lib_loaded="$lib_loaded $1"
    } || eval ${v_lib}_lib_loaded=0

    shift
  done
}

# Test lib exists in scriptpath
uc_lib_exists () # ~ <Name>
{
  command -v $1.lib.sh
}


# Id: user-conf/0.0.1-dev script/uc-lib.lib.sh
# From: script-mpe/0.0.4-dev src/sh/lib/lib.lib.sh
