# Raspberry Pi USB Gadget
This script converts the Raspberry Pi Zero (W), the Raspberry Pi 3A+ or the Raspberry Pi 4 into an USB device, with Ethernet and Keyboard (HID) support.

After installing everything (even `dnsmasq` if you have internet), the USB port on the Zero and in the 3A+ will be in guest mode, and no USB device (i.e. USB wifi dongle) can be added after. The dns server also will give the host the IP `10.42.0.2` and it will give itself (the Raspberry Pi) `10.42.0.1`.

## Installation
`# ./usb-gadget-install.sh`

## HID descriptor and information
The HID device will send the following descriptor with a keyboard device and a consumer device (for Media keys).
- The **device_id** for the keyboard is __*0x01*__ and the length of the message is _**8 Bytes**_. 
  ```sh
  echo "010000${KEY_CODE}00000000" | xxd -r -ps > /dev/hidg0;
  echo "0100000000000000" | xxd -r -ps > /dev/hidg0;
  ```
- The **device_id** for the consumer device is __*0x02*__ and the leng of the message is _**3 Bytes**_.
  ```sh
  echo "02${KEY_CODE}00" | xxd -r -ps > /dev/hidg0;
  echo "020000" | xxd -r -ps > /dev/hidg0;
  ```

```c
/*
//Keyboard
05 01 09 06 a1 01 85 01 05 07 19 e0 29 e7 15 00 25 01 75 01 95 08 81 02 95 01 75 08 81 03 95 05 75 01 05 08 19 01 29 
05 91 02 95 01 75 03 91 03 95 06 75 08 15 00 25 65 05 07 19 00 29 65 81 00 c0 
//Cosumer device
05 0C 09 01 A1 01 85 02 05 0C 15 00 25 01 75 01 95 07 09 B5 09 B6 09 B7 09 CD 09 E2 09 E9 09 EA 81 02 95 06 81 01 C0
*/

0x05, 0x01,        // Usage Page (Generic Desktop Ctrls)
0x09, 0x06,        // Usage (Keyboard)
0xA1, 0x01,        // Collection (Application)
0x85, 0x01,        //   Report ID (1)
0x05, 0x07,        //   Usage Page (Kbrd/Keypad)
0x19, 0xE0,        //   Usage Minimum (0xE0)
0x29, 0xE7,        //   Usage Maximum (0xE7)
0x15, 0x00,        //   Logical Minimum (0)
0x25, 0x01,        //   Logical Maximum (1)
0x75, 0x01,        //   Report Size (1)
0x95, 0x08,        //   Report Count (8)
0x81, 0x02,        //   Input (Data,Var,Abs,No Wrap,Linear,Preferred State,No Null Position)
0x95, 0x01,        //   Report Count (1)
0x75, 0x08,        //   Report Size (8)
0x81, 0x03,        //   Input (Const,Var,Abs,No Wrap,Linear,Preferred State,No Null Position)
0x95, 0x05,        //   Report Count (5)
0x75, 0x01,        //   Report Size (1)
0x05, 0x08,        //   Usage Page (LEDs)
0x19, 0x01,        //   Usage Minimum (Num Lock)
0x29, 0x05,        //   Usage Maximum (Kana)
0x91, 0x02,        //   Output (Data,Var,Abs,No Wrap,Linear,Preferred State,No Null Position,Non-volatile)
0x95, 0x01,        //   Report Count (1)
0x75, 0x03,        //   Report Size (3)
0x91, 0x03,        //   Output (Const,Var,Abs,No Wrap,Linear,Preferred State,No Null Position,Non-volatile)
0x95, 0x06,        //   Report Count (6)
0x75, 0x08,        //   Report Size (8)
0x15, 0x00,        //   Logical Minimum (0)
0x25, 0x65,        //   Logical Maximum (101)
0x05, 0x07,        //   Usage Page (Kbrd/Keypad)
0x19, 0x00,        //   Usage Minimum (0x00)
0x29, 0x65,        //   Usage Maximum (0x65)
0x81, 0x00,        //   Input (Data,Array,Abs,No Wrap,Linear,Preferred State,No Null Position)
0xC0,              // End Collection
0x05, 0x0C,        // Usage Page (Consumer)
0x09, 0x01,        // Usage (Consumer Control)
0xA1, 0x01,        // Collection (Application)
0x85, 0x02,        //   Report ID (2)
0x05, 0x0C,        //   Usage Page (Consumer)
0x15, 0x00,        //   Logical Minimum (0)
0x25, 0x01,        //   Logical Maximum (1)
0x75, 0x01,        //   Report Size (1)
0x95, 0x07,        //   Report Count (7)
0x09, 0xB5,        //   Usage (Scan Next Track)
0x09, 0xB6,        //   Usage (Scan Previous Track)
0x09, 0xB7,        //   Usage (Stop)
0x09, 0xCD,        //   Usage (Play/Pause)
0x09, 0xE2,        //   Usage (Mute)
0x09, 0xE9,        //   Usage (Volume Increment)
0x09, 0xEA,        //   Usage (Volume Decrement)
0x81, 0x02,        //   Input (Data,Var,Abs,No Wrap,Linear,Preferred State,No Null Position)
0x95, 0x06,        //   Report Count (6)
0x81, 0x01,        //   Input (Const,Array,Abs,No Wrap,Linear,Preferred State,No Null Position)
0xC0,              // End Collection

// 104 bytes
```