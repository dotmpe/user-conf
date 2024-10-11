#!/usr/bin/env bash
redo-ifchange _.uc-build.class=class

#: "${CLASS_LIST:=${METADIR:-.meta}/tab/class.list}" &&
#: "${CLASS_CACHE:=${METADIR:-.meta}/cache/class.tab}" &&
#: "${CLASS_SH:=${METADIR:-.meta}/cache/class.sh}" &&
#
#grep '@class\>' "${CTX_TAB:?}" > "${3:?}" &&
#< "${3:?}" redo-stamp
#
