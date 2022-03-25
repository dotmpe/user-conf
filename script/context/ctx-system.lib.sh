#!/bin/sh

ctx_system_lib_load () { :;}
ctx_system_lib_init () { :;}

# @System.init
at_System__init ()
{
true #  lib_require
}

# discover: yield classes (tagrefs) applicable to this host
at_System__discover ()
{
  echo @CPU @Mem @Disk
  #test -z "$(ls -F /sys/bus/cpu/devices/)" || echo @CPU

  case "$(uname -m)" in
    ( armv7l ) ;;
    ( x86_64 ) echo @Motherboard @DMI
      ;;
  esac

  test -z "$(ls -F /sys/bus/pci/devices/)" || echo @PCI
  test -z "$(ls -F /sys/bus/usb/devices/)" || echo @USB
  test -z "$(ls -F /sys/class/net/)" || echo @Net
  test -z "$(ls -F /sys/class/power_supply/)" || echo @PSU
}

at_System__report ()
{
  case "$1" in
    ( lshw-businfo ) sudo lshw -businfo -notime ;;
  # TODO: ignore removable disks, cards?
    ( lshw-notime ) sudo lshw -notime ;;
  esac
}

at_PCI__report ()
{
  test -n "${1:-}" || set -- pci-tree
  case "$1" in
    ( pci-tree ) sudo lspci -tv ;;
    ( pci-devices ) sudo lspci -Dvvv ;;
    ( pci-power ) sudo tlp-stat --pcie ;;
  esac
}

at_CPU__report ()
{
  lscpu
}

at_Mem__report ()
{
  lsmem
}

at_PSU__report ()
{
  tlp-stat --battery
}

at_DMI__report ()
{
  sudo dmidecode
}

@USB.report ()
{
  sudo lsusb -tvv

  local dev

  usb_hubs=$(usb_hubs)

  for dev in `usb_device_bus_ids`
  do
    case " $(echo $usb_hubs) " in ( *" $dev "* ) continue ;; esac
    vendor_product=$(usb_devices "\3" -s $dev)
    echo $dev $(usb_devices "\3 \4" -s $dev)
    #lsusb -vs $dev | tail -n +3
    #echo
  done

  echo `echo "$usb_hubs"|wc -l` hubs
  for dev in $usb_hubs
  do
    echo $dev $(usb_devices "\3 \4" -s $dev)
  done
}

# Print USB device (vendor, product) IDs
usb_device_ids () # ~
{
  usb_devices
}

# Print bus locations of USB devices
usb_device_bus_ids () # ~
{
  usb_devices "\1:\2"
}

# Reformat output of lsusb
usb_devices () # ~ [<format>] [<lsusb-opts>]
{
  local fmt="${1:-}"
  test -n "$fmt" || fmt="\3"
  test $# -eq 0 || shift
  lsusb "$@" | sed -E \
    's/^Bus ([0-9]{3}) Device ([0-9]{3}): ID ([0-9a-f:]+) (.*)$/'"$fmt"'/'
}

usb_device_descr () # ~ <Bus-Id>
{
  lsusb -vs $1 | tail -n +3
}

# Example working on usb_devices et al
usb_hubs ()
{
  for dev in `usb_device_bus_ids`
  do
    usb_device_descr "$dev" |
      grep -q 'bDeviceClass  * 9 Hub' || continue
    echo $dev
  done
}

#
