#!/usr/bin/env bash

ctx_disk_lib__load () { :;}
ctx_disk_lib__init ()
{
  ! { "${DEBUG:-false}" || "${DEV:-false}" || "${INIT:-false}"; } ||
  ${INIT_LOG:?} info ":ctx-disk:lib-init" "Initialized ctx-disk.lib"
}

at_Disk__init ()
{
  lib_require disk
  # FIXME: disktab
}

at_Disk__report ()
{
  test -n "${1:-}" || set -- pci-tree
  case "$1" in

  # TODO: ignore loop etc.
    ( lsblk ) lsblk ;;
  #tlp-stat --disk
  esac
}

#
