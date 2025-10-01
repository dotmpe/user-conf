#!/usr/bin/env bash

set -eETuo pipefail
shopt -s extdebug
: "${C:=${CACHE_DIR:-${METADIR:-.meta}/cache}}"
: "${B:=${BUILD_DIR:-${METADIR:-.meta}/build}}"

case "${xredo_target}" in

( @config )
    redo-ifdone @host-env &&
    redo-ifchange .env
  ;;

( @env:* )
    : "${1#@env:}"
    : "${_//[:,.]/ }"
    declare -p $_ | redo-stamp
    #:pass "$(declare -p $_)" &&
    #redo-stamp <<< "${_}"
  ;;

( @host-env )
    redo-ifchange @env:PATH
  ;;

( .env )
    : "${U_C:=/src/local/user-conf+current}"
    echo "U_C=${U_C}"
    . "${U_C:?}"/tool/uc/part/uc-assert.directive-handlers.bash
    declare -p uc_build_selects
    echo PATH=\$PATH:${U_C:?}/tool/redo/recipe
  ;;

( tool/*/part/-common.sh )
    : "${ENV_CTX:=$$/$0:tool/*/part/common.sh}"
    . "typeset,part,uc.sh" &&
    uc_env_typeset
    exit 123
  ;;

( tool/*/part/*.sh )
    : "${ENV_CTX:=$$/$0:tool/*/part/*.sh}"
    . "fun,script,uc.sh" &&
    exit 123

    shopt -s nullglob
    os_path_add "${U_S:?}/tool/us/part" &&
    os_path_add "${U_S:?}/tool/us/exec" &&
    . "us-env.node.sh" &&
    . "fun,script,uc.sh" &&
    . "common,cache,uc.sh" &&
    us_env_node_init &&
    >&2 us_env_node_list &&
    TODO "build $1" ||
    :failp "E$? during load"
  ;;

( * )
    #>&2 echo "${xredo_build_select}: Unknown target $1"
    return 196
  ;;

esac &&

redo-ifchange "${BASH_SOURCE[0]}"

# ex:ft=bash:
