#!/bin/sh

ctx_disk_lib_load () { :;}
ctx_disk_lib_init () { :;}

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
