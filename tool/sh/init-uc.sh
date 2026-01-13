#!/usr/bin/env bash

# XXX: not sure if lib-init will ever be part of u-c
# FIXME: cleanup, this isnt currently used at all, see us-env

# Main

${LOG:?} info ":tools/u-c:init" "Starting entry..." "0:$0 -:$-"


: "${scriptpathname:="${0}"}"
: "${UCONF:="$HOME/.conf"}"
: "${scriptpath:=$HOME/.conf/script}"

append_path "${U_S?init-uc.sh:U_S setting required}/src/sh/lib"
append_path "${U_C?init-uc.sh:U_C setting required}/script"
append_path "$scriptpath"
export PATH

: "${uc_sh_lib_rest:="vc-uc sd-uc sh-ansi-tpl-uc volume-uc context-uc todotxt-uc"}"


test -n "${scriptname-}" || scriptname="$(basename -- "$scriptpathname" .sh)"
test -n "${verbosity-}" || verbosity=5

#test -z "${__load-}" && {
  test -z "${lib_load-}" && {
    : # test -n "${1-}" && uc_init_act="$1" || uc_init_act=load
  } || uc_init_act="load-ext"
#} || uc_init_act=$__load
$LOG notice ":u-c:init" "Util boot mode" "${uc_init_act-empty}:${uc_init_act:-unset}"

case "${uc_init_act:-}" in

  load-ext ) ;; # External include, do nothing

  load )
      test -n "${scriptpath-}" || scriptpath="$(dirname "$scriptpathname")/script"
      # XXX: . $UCONF/script/user-conf/lib.sh
      #unset UC_LIB_BASE
      #$LOG notice : "Loading" "UC_LIB_BASE=${UC_LIB_BASE:-}"
      : "${UC_LIB_BASE:="$UCONF/script"}"

      uc_fun lib_uc_load || {

        [[ -e "$UC_LIB_BASE"/lib-uc.lib.sh ]] && {
          . "$UC_LIB_BASE"/lib-uc.lib.sh || {
            $LOG error ":u-c:init" "Error loading uc lib" "$UC_LIB_BASE" 1
          }
          #uc_lib_init
        } || {
          $LOG error ":u-c:init" "Error loading uc lib" "$UC_LIB_BASE" 1
        }
      }

      ${lib_load:?} str-uc sys-uc std-uc os-uc shell-uc statusdir-uc ||
        $LOG error ":u-c:init" "Error loading default script libs" "E$?" $? || return
    ;;

  '' ) ;;

  * )
      $LOG warn ":u-c:init" "Ignored extra $scriptname argument(s)" "$0 $*"
    ;;

esac


# Sync: U-S:tool/sh/init-wrapper.sh
# Id: Conf.mpe/0.0.0-dev tool/sh/init-uc.sh
