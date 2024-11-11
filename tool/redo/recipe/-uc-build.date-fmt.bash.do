#!/usr/bin/env bash
set -eETuo pipefail
us-env -r user-script &&
lib_require date date-htd &&
lib_init date &&
  true || $LOG alert :date-fmt "Setup" E$? $? || exit $?

case "${REDO_TARGET:?}" in

( *.date-fmt )
    false # TODO:
  ;;

( *:* )
    <<< "${REDO_TARGET:?}" IFS=: read -r date_{namekey,spec} &&
    date_path=${METADIR?}/build/data/$date_namekey.date &&
    date_ts=$( date_fmt "${date_spec:?}" "%s" ) &&
    echo "${date_ts:?} ${date_spec:?}" >| "${date_path}" &&
    touch -d @${date_ts:?} "$date_path"
  ;;

esac &&

redo-always
