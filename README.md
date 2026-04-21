# Tiny FEX
I don’t like huge rootfs.
- I only need to run [steamcmd](https://developer.valvesoftware.com/wiki/SteamCMD) and [vanilla starbound server](https://github.com/gammamonbiscuit/starbound-ampere-server), not full-on triple A titles in linux desktop
- Squashfuse and such are great, but FUSE in docker is privileged, using it uncompressed makes it crazy huge
- `debootstrap` works well (example below), but I want to do it in a funny way :p

So I use Debian’s distro image as rootfs.

>[!WARNING]
>No docker image is available for download, you have to build it yourself,
>this is just an example of how to do this.
>**No support will be provided!**

## Usage
After building the image, run it and you can use FEX-emu’s commands. 
```
docker run -it --rm tiny-fex
# uname -a
Linux f196546109df 6.12.74+deb13+1-arm64 #1 SMP Debian 6.12.74-2 (2026-03-08) aarch64 GNU/Linux
# FEXBash
FEXBash-root@f196546109df:/> uname -a
Linux f196546109df 6.11.0 # SMP Apr 21 2026 14:08:22 x86_64 GNU/Linux
```

## debootstrap
Here’s how to make a rootfs using debootstrap, `lib32gcc-s1` is the example dependency again.
I wasted a lot of time before figuring out I need to chroot for the second stage :(
```shell
cd /rootfs
debootstrap --foreign --arch=amd64 --variant=minbase --include=lib32gcc-s1 trixie . "http://deb.debian.org/debian"
chroot . /debootstrap/debootstrap --second-stage
```