#!/bin/sh

# XXX: not sure if lib-init will ever be part of u-c

# Main

${LOG:?} info ":tools/u-c:init" "Starting entry..." "0:$0 -:$-"


true "${scriptpathname:="${0}"}"
true "${UCONF:="$HOME/.conf"}"
true "${scriptpath:=$HOME/.conf/script}"

append_path "$U_S/src/sh/lib"
append_path "$U_C/script"
append_path "$scriptpath"
export PATH

true "${default_sh_lib:="str-uc sys-uc std-uc os-uc shell-uc statusdir-uc"}"
true "${uc_sh_lib_rest:="vc-uc sd-uc sh-ansi-tpl-uc volume-uc context-uc todotxt-uc"}"


test -n "${scriptname-}" || scriptname="$(basename -- "$scriptpathname" .sh)"
test -n "${verbosity-}" || verbosity=5

test -z "${__load-}" && {
  test -z "${__load_lib-}" && {
    test -n "${1-}" && uc_init_act="$1" || uc_init_act=load
  } || uc_init_act="load-ext"
} || uc_init_act=$__load
$LOG notice ":u-c:init" "Util boot mode" "$uc_init_act"

case "$uc_init_act" in

  load-ext ) ;; # External include, do nothing

  load )
      test -n "${scriptpath-}" || scriptpath="$(dirname "$scriptpathname")/script"
      # XXX: . $UCONF/script/user-conf/lib.sh
      #unset UC_LIB_PATH
      #$LOG notice : "Loading" "UC_LIB_PATH=${UC_LIB_PATH:-}"
      true "${UC_LIB_PATH:="$UCONF/script"}"

      ${sh_assert_func:-uc_func} ${lib_load:=uc_lib_load} || {

        test -e $UC_LIB_PATH/uc-lib.lib.sh && {
          . $UC_LIB_PATH/uc-lib.lib.sh || {
            $LOG error ":u-c:init" "Error loading uc lib" "$UC_LIB_PATH" 1
          }
          #uc_lib_init
        } || {
          $LOG error ":u-c:init" "Error loading uc lib" "$UC_LIB_PATH" 1
        }
      }

      ${lib_load:?} $default_sh_lib || {
        $LOG error ":u-c:init" "Error loading script libs" "E$?:$default_sh_lib" "$?"
	return $?
      }
    ;;

  '' ) ;;

  * )
      $LOG warn ":u-c:init" "Ignored extra $scriptname argument(s)" "$0 $*"
    ;;

esac


# Sync: U-S:tools/sh/init-wrapper.sh
# Id: Conf.mpe/0.0.0-dev tools/sh/init-uc.sh
