#!/usr/bin/env bash

xredo_name=-uc-build.date-fmt.bash.do
xredo_targetname=${REDO_TARGET%.do}

set -eETuo pipefail
us-env -r user-script &&
lib_require date date-htd &&
lib_init date &&
  true || $LOG alert :date-fmt "Setup" E$? $? || exit $?

: "${XREDO_BUILD:=@build:/}"
>&2 _IFDBG declare -p XREDO_BUILD

>&2 _IFDBG echo ":$xredo_targetname: case ${REDO_PWD}/${REDO_TARGET:?}" in

case "${REDO_PWD}/${REDO_TARGET:?}" in

( "${XREDO_BUILD}"*.date-fmt )
    false # TODO:
  ;;

( "${XREDO_BUILD}date:"*:*:*:* )
  : "${REDO_PWD:?}/${xredo_targetname}"
  : "${_:${#XREDO_BUILD}}"
  ref=${_#date:}
  >&2 _IFDBG _IFVBS declare -p ref

  <<< "${ref:1}" IFS=: read -r date_{namekey,spec,cmp,file} &&
  date_path=${B?}/data/${date_namekey:?}.date &&
  date_ts=$( date_fmt "${date_spec:?}" "%s" ) &&
  >&2 _IFDBG _IFVBS declare -p date_{path,spec,cmp,file,ts} &&
  >| "${date_path}" echo "${date_ts:?} ${date_spec:?}" &&
  touch -d @${date_ts:?} "$date_path" &&
  redo-always &&
  test "$date_path" "$date_cmp" "$date_file"
  ;;

( "${XREDO_BUILD}date:"*:* )
  : "${REDO_PWD:?}/${xredo_targetname}"
  : "${_:${#XREDO_BUILD}}"
  ref=${_#date:}
  >&2 _IFDBG _IFVBS declare -p ref

  <<< "${ref:1}" IFS=: read -r date_{namekey,spec} &&
  date_path=${B?}/data/${date_namekey:?}.date &&
  date_ts=$( date_fmt "${date_spec:?}" "%s" ) &&
  >&2 _IFDBG _IFVBS declare -p date_{path,spec,ts} &&
  >| "${date_path}" echo "${date_ts:?} ${date_spec:?}" &&
  touch -d @${date_ts:?} "$date_path"
  ;;

esac &&

redo-always
