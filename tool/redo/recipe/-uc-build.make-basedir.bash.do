#!/usr/bin/env bash

#[[ $REDO_TARGET != default ]] || set --
case "${REDO_TARGET:?}" in
( default | default.* )
  set --
;;
esac

cd "${REDO_BASE:?}" &&
make "$@" &&
redo-always
