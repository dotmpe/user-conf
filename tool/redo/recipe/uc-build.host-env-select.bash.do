#!/usr/bin/env bash

: "${C:=$(realpath --relative-to "${REDO_BASE}" "${CACHE_DIR:-${METADIR:-.meta}/cache}")}"
: "${B:=$(realpath --relative-to "${REDO_BASE}" "${BUILD_DIR:-${METADIR:-.meta}/build}")}"

case "${xredo_target}" in

( @config )
    redo-ifdone @host-env &&
    redo-ifchange .env
  ;;

( @env:* )
    : "${1#@env:}"
    : "${_//[:,]/ }"
    declare -p $_ | redo-stamp
    #:pass "$(declare -p $_)" &&
    #redo-stamp <<< "${_}"
  ;;

( @host-env:lookup:* )
    : "${1#@host-env:lookup:}"
    : "${_//[:,]/ }"
    #redo-ifchange
    redo-always
  ;;

( @host-env )
    TODO "Check/update /etc/uc"
  ;;

( @tools )
    redo "tool/*/part"

    local -a partnames targets
    partnames=( common profile interactive )
    : "$(printf 'tool/sh/part/%s.bash\ntool/sh/part/%s.sh\n' "${partnames[@]}")"
    <<< "${_}" mapfile -t targets &&
    redo-ifchange "${targets[@]}"
  ;;

( .env )
    : "${U_C:=/src/local/user-conf+current}"
    echo "U_C=${U_C}"
    . "${U_C:?}"/tool/uc/part/uc-assert.directive-handlers.bash
    declare -p uc_build_selects
    echo PATH=\$PATH:${U_C:?}/tool/redo/recipe
  ;;

( * ) return ${_E_next:-196}

esac &&

redo-ifchange "${BASH_SOURCE[0]}"

# Id uc-build.host-env-select.bash recipe-select ex:ft=bash:
