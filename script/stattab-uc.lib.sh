#!/usr/bin/env bash

### StatTab-UC

# Functions to retrieve simple status record using fetch/grep and parse them.

# Started adding psuedo-class to deal with simultaneous instances (and subtypes)


stattab_uc_lib__load ()
{
  lib_require stattab-reader stattab-class str-uc date-uc todotxt || return
  # XXX: lib_require_alt str-htd str-uc || return
  #lib_require str-uc || return
  : "${gsed:=sed}"
  test -n "${HOME-}" || HOME=/srv/home-local
  test -n "${UCTAB-}" || UCTAB=$HOME/.local/statusdir/index/status-uc.tab
}

# Derive: BIN:
