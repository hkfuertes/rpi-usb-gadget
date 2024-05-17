Pre-built Raspberry Pi images to simplify using the Pi as a USB gadget.

The basic Raspberry Pi OS images are a faithful reproduction of the work done by [Ben Hardill][bh],
with some additional automation wrapped around to get to a publish release on GitHub.

Other operating systems are derived from the basic template used in Raspberry Pi OS.

## Building Images with Docker

The easiest way to build images locally is to use the pre-built [`packer-builder-arm`][pba] Docker images

```
docker compose run --rm [lite64|lite]
```
To use new images it should be enougth to update the urls in the `docker-compose.yaml` file.
```yaml
...
  lite64:
    <<: *builder
    environment:
      - IMG_URL=https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-15/2024-03-15-raspios-bookworm-arm64-lite.img.xz
      - FILENAME=raspios-lite-arm64.img

  lite:
    <<: *builder
    environment:
      - IMG_URL=https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2024-03-15/2024-03-15-raspios-bookworm-armhf-lite.img.xz
      - FILENAME=raspios-lite-armhf.img
...
```

## Disable UASP
Several SATA to USB adapter (I've got two) have their UASP chip/protocol not compatible with Raspberry PI. We can disable it for those specific devices.
> https://www.raspberrypi.org/forums/viewtopic.php?f=28&t=245931

After running `lsusb` you will see an output similar to this:
```console
hkfuertes@terminus:~$ lsusb
...            
Bus 001 Device 016: ID 174c:1153 ASMedia Technology Inc. ASM1153 SATA 3Gb/s bridge
...
```
We need on the second line **idVendor** and **idProduct**: *174c* and *1153*.

Then we modify the `/boot/cmdline.txt` file (`sudo nano /boot/cmdline.txt`) and we add in the begining the following string: 
```console
usb-storage.quirks=174c:1153:u
```
  > If we have several devices separate the multiple `idVendor:idProduct:u` with a comma.

### My Adapters Strings:
- `usb-storage.quirks=152d:0578:u`: JMicron Technology Corp. / JMicron USA Technology Corp. JMS578 SATA 6Gb/s
- `usb-storage.quirks=174c:1153:u`: ASMedia Technology Inc. ASM1153 SATA 3Gb/s bridge
- `usb-storage.quirks=03f0:0c5b:u`: HP, Inc x5600c (USB 3.2 Pendrive)

## Manual Steps First boot for `devenv`
```shell
# Run docer non root
sudo usermod -aG docker $USER
# Enable codeserver for the current user
sudo systemctl enable --now code-server@$USER
```


[packer]: https://www.packer.io/
[pba]: https://github.com/mkaczanowski/packer-builder-arm
[bh]: https://www.hardill.me.uk/wordpress/2020/02/21/building-custom-raspberry-pi-sd-card-images/
[go]: https://golang.org
[rpimg]: https://www.raspberrypi.com/software/
