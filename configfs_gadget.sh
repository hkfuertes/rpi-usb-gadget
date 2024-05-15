#!/bin/bash
cd /sys/kernel/config/usb_gadget/
mkdir -p configfs_gadget && cd configfs_gadget
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB # USB2
mkdir -p strings/0x409
echo "1234567890" > strings/0x409/serialnumber
echo "Raspberry Pi Foundation" > strings/0x409/manufacturer
echo "Raspberry Pi USB Device" > strings/0x409/product
mkdir -p configs/c.1/strings/0x409
echo "Network" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

HOST="48:6f:73:74:50:43" # "HostPC"
SELF="42:61:64:55:53:42" # "BadUSB"

mkdir -p os_desc
echo "1" > os_desc/use
ms_vendor_code="0xcd" # Microsoft
ms_qw_sign="MSFT100" # also Microsoft (if you couldn't tell)
echo $ms_vendor_code > os_desc/b_vendor_code
echo $ms_qw_sign > os_desc/qw_sign
ln -s ${gadget}/configs/c.1 ${gadget}/os_desc

# ECM Network
# mkdir -p functions/ecm.usb0
# echo $HOST > functions/ecm.usb0/host_addr
# echo $SELF > functions/ecm.usb0/dev_addr
# ln -s functions/ecm.usb0 configs/c.1/

mkdir -p functions/rndis.usb0
echo $SELF > functions/rndis.usb0/dev_addr
echo $HOST > functions/rndis.usb0/host_addr

ms_compat_id="RNDIS" # matches Windows RNDIS Drivers
ms_subcompat_id="5162001" # matches Windows RNDIS 6.0 Driver
echo $ms_compat_id > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo $ms_subcompat_id > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id
ln -s functions/rndis.usb0 configs/c.1/

# Mass Storage
# FILE=/opt/disk.img
# mkdir -p ${FILE/img/d}
# mount -o loop,ro, -t exfat $FILE ${FILE/img/d}
# mkdir -p functions/mass_storage.usb0
# echo 0 > functions/mass_storage.usb0/stall
# echo 0 > functions/mass_storage.usb0/lun.0/cdrom
# echo 0 > functions/mass_storage.usb0/lun.0/ro
# echo 0 > functions/mass_storage.usb0/lun.0/nofua
# echo $FILE > functions/mass_storage.usb0/lun.0/file
# ln -s functions/mass_storage.usb0 configs/c.1/

# End functions
ls /sys/class/udc > UDC

