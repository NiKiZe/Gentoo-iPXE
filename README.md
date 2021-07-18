# Gentoo-iPXE
Sample to support iPXE boot of Gentoo Minimal

This is to show and use how Gentoo now can be booted over PXE since https://bugs.gentoo.org/396467 was resolved
in https://gitweb.gentoo.org/proj/genkernel.git/commit/?id=24ad5065fa856389ee9b058f57adffbe752da157

This sample is also available at http://b800.org/gentoo/boot.ipxe

## To provide your own mirror
make sure you have a boot.ipxe script with the minimal configuration.
Use `gentoocd_unpack.sh` to download latest iso and unpack needed files.
If you want to do this yourself then it is
* `/boot/gentoo`
* `/boot/gentoo.igz`
* `/image.squashfs`
that you need to extract and make available for your PXE infrastructure