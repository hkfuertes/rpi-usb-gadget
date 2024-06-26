#!/bin/bash

# Typical location of this file is /usr/local/bin/gadget

# USB Gadget for Raspbery Pi 4 Ethernet-over-USB
#
# Copyright (C) 2023 Victor Rybynok <v.rybynok@gmail.com>
#
# This script is based on the original work of
# David Lechner <david@lechnology.com>:
# https://github.com/ev3dev/ev3-systemd/blob/ev3dev-jessie/scripts/ev3-usb.sh
#
# It has also been influenced by Ben Hardill's blog post:
# https://www.hardill.me.uk/wordpress/2020/02/21/building-custom-raspberry-pi-sd-card-images/
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.

set -eu
set -o pipefail

# Command line parameters

# "up" or "down"
readonly COMMAND="$1"

# A UDC device name - RPi4 only has only one UDC", thus:
# UDC_DEVICE="$(ls /sys/class/udc)"
UDC_DEVICE="fe980000.usb" # Assuming that this number is the same accross RPi 4
readonly UDC_DEVICE

g="/sys/kernel/config/usb_gadget/pi4"

rpi4_usb_up() {
  # USB C port on Raspberry Pi only supports USB 2.0 standard.
  # USB 2.0 max current is 500mA. However, Raspbery Pi 4 under load can consume
  # above 1A and a lot more with HATs. Pi 4 specs suggest that USB C min current
  # should be 3A.
  # USB 3.2 standard support up to 3A therefore setting USB_VER to 0x0320
  # instead of 0x0200.
  # So far I have not noticed and side effects with this USB_VER upgrade.
  # readonly USB_VER="0x0200" # USB 2.0
  readonly USB_VER="0x0320"
  readonly DEV_CLASS="2" # Communications
  readonly VID="0x1d6b" # Linux Foundation
  readonly PID="0x0104" # Multifunction Composite Gadget

  # DEVICE should be incremented any time there are breaking changes to this
  # script so that the host OS sees it as a new device and re-enumerates
  # everything rather than relying on cached values
  readonly DEVICE="0x0100"

  readonly MANF="ramblehead"
  readonly PROD="rh-rpi"

  # Using CPU serial as the device serial
  SERIAL="$(grep Serial /proc/cpuinfo | sed 's/Serial\s*:\s*\(\w*\)/\1/')"
  readonly SERIAL
  readonly ATTR="0x80" # Bus-powered, no remote wakeup support.
  readonly PWR="375" # USB 3.2 Type-C supports up to 3A; 8 mA units
  readonly CFG_CDC="CDC"
  readonly CFG_RNDIS="RNDIS"

  # Using device/CPU serial to generate MAC addresses

  # Add colons for MAC address format
  MAC="$(echo "${SERIAL}" | sed 's/\(\w\w\)/:\1/g' | cut -b 8-)"
  readonly MAC

  # Change the first number for each MAC address - the second digit of 2 indicates
  # that these are "locally assigned (b2=1), unicast (b1=0)" addresses. This is
  # so that they don't conflict with any existing vendors. Care should be taken
  # not to change these two bits.
  DEV_MAC1="02$(echo "${MAC}" | cut -b 3-)"
  HOST_MAC1="12$(echo "${MAC}" | cut -b 3-)"
  DEV_MAC2="22$(echo "${MAC}" | cut -b 3-)"
  HOST_MAC2="32$(echo "${MAC}" | cut -b 3-)"
  readonly DEV_MAC1
  readonly HOST_MAC1
  readonly DEV_MAC2
  readonly HOST_MAC2

  MS_VENDOR_CODE="0xcd" # Microsoft
  MS_QW_SIGN="MSFT100" # Also Microsoft (if you couldn't tell)
  MS_COMPAT_ID="RNDIS" # Matches Windows RNDIS Drivers
  MS_SUBCOMPAT_ID="5162001" # Matches Windows RNDIS 6.0 Driver
  readonly MS_VENDOR_CODE
  readonly MS_QW_SIGN
  readonly MS_COMPAT_ID
  readonly MS_SUBCOMPAT_ID

  if [ -d ${g} ]; then
    if [ "$(cat ${g}/UDC)" != "" ]; then
      echo "Gadget is already up."
      exit 1
    fi
    echo "Cleaning up old directory..."
    rpi4_usb_down
  fi

  echo "Setting up gadget..."

  # Create a new gadget
  mkdir ${g}
  echo "${USB_VER}" > ${g}/bcdUSB
  echo "${DEV_CLASS}" > ${g}/bDeviceClass
  echo "${VID}" > ${g}/idVendor
  echo "${PID}" > ${g}/idProduct
  echo "${DEVICE}" > ${g}/bcdDevice
  mkdir ${g}/strings/0x409
  echo "${MANF}" > ${g}/strings/0x409/manufacturer
  echo "${PROD}" > ${g}/strings/0x409/product
  echo "${SERIAL}" > ${g}/strings/0x409/serialnumber

  # Create two configurations. The first will be CDC. The second will be RNDIS.
  # Due to OS_DESC, Windows should use the second configuration.

  # config 1 is for CDC

  mkdir ${g}/configs/c.1
  echo "${ATTR}" > ${g}/configs/c.1/bmAttributes
  echo "${PWR}" > ${g}/configs/c.1/MaxPower
  mkdir ${g}/configs/c.1/strings/0x409
  echo "${CFG_CDC}" > ${g}/configs/c.1/strings/0x409/configuration

  # Create the CDC function

  mkdir ${g}/functions/ecm.usb0
  echo "${DEV_MAC1}" > ${g}/functions/ecm.usb0/dev_addr
  echo "${HOST_MAC1}" > ${g}/functions/ecm.usb0/host_addr

  # config 2 is for RNDIS

  mkdir ${g}/configs/c.2
  echo "${ATTR}" > ${g}/configs/c.2/bmAttributes
  echo "${PWR}" > ${g}/configs/c.2/MaxPower
  mkdir ${g}/configs/c.2/strings/0x409
  echo "${CFG_RNDIS}" > ${g}/configs/c.2/strings/0x409/configuration

  # On Windows 7 and later, the RNDIS 5.1 driver would be used by default,
  # but it does not work very well. The RNDIS 6.0 driver works better. In
  # order to get this driver to load automatically, we have to use a
  # Microsoft-specific extension of USB.

  echo "1" > ${g}/os_desc/use
  echo "${MS_VENDOR_CODE}" > ${g}/os_desc/b_vendor_code
  echo "${MS_QW_SIGN}" > ${g}/os_desc/qw_sign

  # Create the RNDIS function, including the Microsoft-specific bits

  mkdir ${g}/functions/rndis.usb0
  echo "${DEV_MAC2}" > ${g}/functions/rndis.usb0/dev_addr
  echo "${HOST_MAC2}" > ${g}/functions/rndis.usb0/host_addr
  echo "${MS_COMPAT_ID}" > ${g}/functions/rndis.usb0/os_desc/interface.rndis/compatible_id
  echo "${MS_SUBCOMPAT_ID}" > ${g}/functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

  # Link everything up and bind the USB device

  ln -s ${g}/functions/ecm.usb0 ${g}/configs/c.1
  ln -s ${g}/functions/rndis.usb0 ${g}/configs/c.2
  ln -s ${g}/configs/c.2 ${g}/os_desc
  echo "${UDC_DEVICE}" > ${g}/UDC

  echo "Done."
}

rpi4_usb_down() {
  if [ ! -d ${g} ]; then
    echo "Gadget is already down."
    exit 1
  fi

  echo "Taking down gadget..."

  # Have to unlink and remove directories in reverse order.
  # Checks allow to finish takedown after error.

  if [ "$(cat ${g}/UDC)" != "" ]; then
      echo "" > ${g}/UDC
  fi

  rm -f ${g}/os_desc/c.2
  rm -f ${g}/configs/c.2/rndis.usb0
  rm -f ${g}/configs/c.1/ecm.usb0
  [ -d ${g}/functions/ecm.usb0 ] && rmdir ${g}/functions/ecm.usb0
  [ -d ${g}/functions/rndis.usb0 ] && rmdir ${g}/functions/rndis.usb0
  [ -d ${g}/configs/c.2/strings/0x409 ] && rmdir ${g}/configs/c.2/strings/0x409
  [ -d ${g}/configs/c.2 ] && rmdir ${g}/configs/c.2
  [ -d ${g}/configs/c.1/strings/0x409 ] && rmdir ${g}/configs/c.1/strings/0x409
  [ -d ${g}/configs/c.1 ] && rmdir ${g}/configs/c.1
  [ -d ${g}/strings/0x409 ] && rmdir ${g}/strings/0x409
  rmdir ${g}

  echo "Done."
}

case ${COMMAND} in
up)
  rpi4_usb_up
  ;;
down)
  rpi4_usb_down
  ;;
*)
  echo "Usage: rpi4-usb.sh up|down"
  exit 1
  ;;
esac
