Pre-built Raspberry Pi images to simplify using the Pi as a USB gadget.

The basic Raspberry Pi OS images are a faithful reproduction of the work done by [Ben Hardill][bh],
with some additional automation wrapped around to get to a publish release on GitHub.

Other operating systems are derived from the basic template used in Raspberry Pi OS.

## Building Images with Docker

The easiest way to build images locally is to use the pre-built [`packer-builder-arm`][pba] Docker images

```
docker compose run [lite64|lite]
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


[packer]: https://www.packer.io/
[pba]: https://github.com/mkaczanowski/packer-builder-arm
[bh]: https://www.hardill.me.uk/wordpress/2020/02/21/building-custom-raspberry-pi-sd-card-images/
[go]: https://golang.org
[rpimg]: https://www.raspberrypi.com/software/
