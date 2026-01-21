#!/usr/bin/env bash
# shellcheck disable=2128 # using short notation to acces initial array value
#
ctx_system_lib__load () { :;}
ctx_system_lib__init () {
  local bin prereq
  prereq="lscpu lshw lsmem lspci lsusb sudo"
  case "${HOSTTYPE:-$(uname -m)}" in
    ( x86_64 ) prereq+=" dmidecode" ;;
  esac
  [[ -z "$(command ls /sys/class/power_supply/BAT*)" ]] || prereq+=" dmidecode"
  for bin in $prereq
  do
    local -n _atSys_bin1=${bin}_bin
    if_ok "$(command -v $bin)" &&
    _atSys_bin1=$_ ||
      failerr "Required command: $bin" || return
  done
  [[ ! ${DISPLAY-} ]] ||
    for bin in lshw-gtk usbview
    do
      local -n _atSys_bin1=${bin}_bin
      if_ok "$(command -v $bin)" &&
      _atSys_bin1=$_ || _ failerr "Suggested install: $bin (ignored)"
    done
}

# @System.init
@System.init ()
{
  :
}

# discover: yield classes (tagrefs) applicable to this host
@System.discover ()
{
  local -n to=${1:?}

  to+=( @CPU @Mem @Disk )

  case "${HOSTTYPE:-$(uname -m)}" in
    ( armv7l ) ;;
    ( x86_64 ) to+=( @Motherboard @DMI ) ;;
  esac

  [[ ! ${DISPLAY-} ]] || to+=( @X11 )

  [[ -z "$(command ls /sys/bus/pci/devices/)" ]] || to+=( @PCI )
  [[ -z "$(command ls /sys/bus/usb/devices/)" ]] || to+=( @USB )
  # shellcheck disable=2143 # erroneous trigger
  [[ -z "$(grep -v '\<lo\>' < <(command ls /sys/class/net/))" ]] || to+=( @Net )
  [[ -z "$(command ls /sys/class/power_supply/BAT*)" ]] || to+=( @Battery )
  [[ -z "$(command ls /sys/class/power_supply/AC*)" ]] || to+=( @Power )
}

@System.report ()
{
  local sudo
  [[ "${1:?}" != lshw* ]] ||
    sudo_require $FUNCNAME:$1 lshw || return
  case "${1:?}" in
  # TODO: ignore removable disks, cards?
  ( lshw.out ) "${sudo[@]}" lshw -notime ;;
  ( lshw,pub.out ) "${sudo[@]}" lshw -notime -sanitize ;;
  ( lshw,businfo.out ) "${sudo[@]}" lshw -businfo ;;
  ( lshw.json )
        "${sudo[@]}" lshw -notime -json |
        jq 'walk(
                if type == "object" and .class? == "processor"
                then del(.size) else . end)'
    ;;

  ( --summary )
      jq -r '"Host \(.id) is a \(.vendor) brand '\''\(.version)'\'' \(.description)
Model: \(.product)
Serial: \(.serial)"'

      jq -r '{
    core: {
      cpus: [
        .. | select(type=="object" and .class?=="processor") |
        {
          product: (.product // "unknown"),
          max_ghz: ((.capacity // .size // 0) / 1e6),
          cores:   (.configuration.cores // "n/a"),
          threads: (.configuration.threads // "n/a"),
          vendor:  (.vendor // "unknown")
        }
      ],
      cache: [
        .. | select(type=="object" and .class?=="memory" and (.id? | test("^cache:"))) |
        {
          id:      (.id // "unknown"),
          size:    (.size // "n/a"),
          level:   (.level? // "?"),
          type:    (.description // .product // "unknown"),
          vendor:  (.vendor // "unknown")
        }
      ],
      memory: [
        .. | select(type=="object" and .class?=="memory" and (.id? | test("^bank:"))) |
        {
          id:       (.id // "unknown"),
          size:     (.size // "n/a"),
          description: (.description // .product // "unknown"),
          clock:    (.clock // "n/a"),
          vendor:   (.vendor // "unknown")
        }
      ]
    },
    storage: {
      interfaces: [
        .. | select(type=="object" and .class?=="storage") |
        {
          id:       (.id // "unknown"),
          type:     (.type // "unknown"),
          vendor:   (.vendor // "unknown")
        }
      ],
      disks: [
        .. | select(type=="object" and .class?=="disk") |
        {
          id:            (.id // "unknown"),
          description:   (.description // "unknown"),
          product:       (.product // "unknown"),
          size:         (.size // "unknown")
        }
      ]
    }
  }
'
    ;;

  ( * ) failerr "No such choice ${1@Q}" ${_E_nsk}
  esac
}

@Battery.report ()
{
  local sudo
  [[ "${1:?}" != tlp-stat* ]] ||
    sudo_require $FUNCNAME:$1 tlp-stat || return
  case "$1" in
  ( tlp-stat,battery.out ) "${sudo[@]}" tlp-stat --battery ;;

  ( * ) failerr "No such choice ${1@Q}" ${_E_nsk}
  esac
}

@CPU.report ()
{
  case "${1:?}" in
  ( lscpu.json ) lscpu --json ;;

  ( * ) failerr "No such choice ${1@Q}" ${_E_nsk}
  esac
}

@DMI.report ()
{
: about 'List all hardware components from DMI/SMBIOS table'
  local sudo
  [[ "${1:?}" != dmidecode* ]] ||
    sudo_require $FUNCNAME:$1 dmidecode || return
  case "${1:?}" in
  ( dmidecode.out ) "${sudo[@]}" dmidecode ;;

  ( * ) failerr "No such choice ${1@Q}" ${_E_nsk}
  esac
}

@Mem.report ()
{
: about 'List all memory blocks'
  case "${1:?}" in
  ( lsmem.out ) lsmem --output-all ;;
  ( lsmem,all.out ) lsmem --all --output-all ;;
  ( lsmem,all,bytes.json ) lsmem --all --bytes --json --output-all ;;
  ( lsmem,bytes.json ) lsmem --bytes --json --output-all ;;

  ( * ) failerr "No such choice ${1@Q}" ${_E_nsk}
  esac
}

@Net.report ()
{
  case "${1:?}" in
  ( ip,address.out ) ip a ;;
  ( ip,route.out ) ip r ;;

  ( * ) failerr "No such choice ${1@Q}" ${_E_nsk}
  esac
}

@PCI.report ()
{
: about 'Peripheral Component Interconnect bus'
  local sudo
  [[ "${1:?}" != tlp-stat* ]] ||
    sudo_require $FUNCNAME:$1 tlp-stat || return
  case "$1" in
  ( lspci.out ) lspci -Dvv ;;
  ( lspci,tree.out ) lspci -tv ;;
  ( tlp-stat,pcie.out ) "${sudo[@]}" tlp-stat --pcie ;;

  ( * ) failerr "No such choice ${1@Q}" ${_E_nsk}
  esac
}

@Power.report ()
{
: about 'AC power state'
  case "${1:?}" in
  ( power,online.out ) cat /sys/class/power_supply/AC/online ;;
  ( * ) failerr "No such choice ${1@Q}" ${_E_nsk}
  esac
}

@USB.report ()
{
: about 'List all USB devices'
  [[ "${1:?}" != lsusb,details* ]] ||
    sudo_require $FUNCNAME:$1 lsusb,details || return
  case "${1:?}" in
  ( lsusb.out ) lsusb ;;
  ( lsusb,details.out ) "${sudo[@]}" lsusb -v ;;

  ( lsusb,id,tree.out ) lsusb -tv ;;
  ( lsusb,id,dev,tree.out ) lsusb -tvv ;;
  ( lsusb,tree.out ) lsusb -t ;;

  ( * ) failerr "No such choice ${1@Q}" ${_E_nsk}
  esac
}

@USB.x-report-hubs ()
{
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

@X11.report ()
{
  case "${1:?}" in
  ( fc-list.out ) fc-list ;;
  ( xrandr.out ) xrandr --verbose ;;
  ( xrdb.out ) xrdb -query ;;

  ( * ) failerr "No such choice ${1@Q}" ${_E_nsk}
  esac
}


sudo_require ()
{
  sudo -nv || test -t 0 ||
    failerr "Sudo required for $1:$2 but no valid session and input is non-interactive" || return
  sudo=( sudo -p "Enter sudo pass to run $2: "  )
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
