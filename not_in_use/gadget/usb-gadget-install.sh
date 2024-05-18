#!/bin/bash

# Check for SU
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

#USB Gadget
echo "dtoverlay=dwc2,dr_mode=peripheral" | sudo tee -a /boot/config.txt
echo "dwc2" | sudo tee -a /etc/modules
echo "libcomposite" | sudo tee -a /etc/modules

# We need to copy the usb-gadget.sh first to the right location.
sudo cp ./usb-gadget.sh /usr/bin/usb-gadget.sh
sudo chmod +x /usr/bin/usb-gadget.sh
#sudo sed -i -e '$i \/usr/bin/usb-gadget.sh\n' /etc/rc.local
#sudo echo "/usr/bin/usb-gadget.sh" >> /etc/rc.local
sudo cp usb-gadget.service /etc/systemd/system/
sudo systemctl enable usb-gadget.service

#Check internet
wget -q --tries=10 --timeout=20 --spider http://google.com
if [[ $? -eq 0 ]]; then
    apt update
    apt install -y dnsmasq

    if [[ ! -e /etc/dnsmasq.d/usb ]] ; then
        echo "interface=usb0" > /etc/dnsmasq.d/usb
        echo "dhcp-range=10.42.0.2,10.42.0.6,255.255.255.248,1h" >> /etc/dnsmasq.d/usb
        echo "dhcp-option=3" >> /etc/dnsmasq.d/usb
        echo "leasefile-ro" >> /etc/dnsmasq.d/usb
        echo "Created /dnsmasq.d/usb"
    fi
fi

# if [[ ! -e /etc/network/interfaces.d/usb0 ]] ; then
#     echo "auto usb0" > /etc/network/interfaces.d/usb0
#     echo "allow-hotplug usb0" >> /etc/network/interfaces.d/usb0
#     echo "iface usb0 inet static" >> /etc/network/interfaces.d/usb0
#     echo "  address 10.42.0.1" >> /etc/network/interfaces.d/usb0
#     echo "  netmask 255.255.255.248" >> /etc/network/interfaces.d/usb0
#     echo "Created /etc/network/interfaces.d/usb0"
# fi
