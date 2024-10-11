#!/usr/bin/env bash
: "${DIAG_TRGT_LIST:=${METADIR:-.meta}/tab/diag.build.list}"
redo-ifchange ${DIAG_TRGT_LIST:?}
true
#
