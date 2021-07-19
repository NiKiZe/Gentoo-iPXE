# Gentoo-iPXE
Example on Minimal Gentoo PXE boot

## Background
This is to show and use how Gentoo can be booted over PXE since [#396467](https://bugs.gentoo.org/396467) was resolved
in [24ad50](https://github.com/gentoo/genkernel/commit/24ad5065fa856389ee9b058f57adffbe752da157)

## Quick start
If EFI boot, make sure you have latest version of iPXE, at least on or after commit [e5f025](https://github.com/ipxe/ipxe@e5f02551735922eb235388bff08249a6f31ded3d)
Latest prebuilt can be found at http://boot.ipxe.org
* Get into the iPXE shell (from PXE boot or even from one of the disk images)
* Get ip `dhcp`
* Start script `chain http://b800.org/gentoo/boot.ipxe`

## Explanation of script
If a file is referred to in a iPXE script, and not given as absolute path, then it tries to load from the "last path"
* `initrd gentoo.igz` - downloads gentoo.igz into memory - you can give the full path over http or tftp if you want to.
* `kernel gentoo root=/dev/ram0 init=/linuxrc  dokeymap looptype=squashfs loop=/image.squashfs  cdroot vga=791 initrd=initrd.magic` - download gentoo kernel image, and append standard cmdline as seen in isolinux/grub, the last initrd= is for EFI boot
* `initrd image.squashfs /image.squashfs` - download squashfs, the second argument tells which name to use in CPIO archive, and will be appended to gentoo.igz
* `boot` - boot

`initrd.magic` is needed in EFI mode, and is a special file in iPXE since [e5f025](https://github.com/ipxe/ipxe@e5f02551735922eb235388bff08249a6f31ded3d) that combines all initrd files into one CPIO archive
If you don't want to rely on this, or if you want to use some other PXE loader, then you can combine squashfs file into gentoo.igz, untested, but it might be possible to use `echo image.squashfs | cpio -H newc -o > gentoo.igz` to create this file

## To create your own mirror
make sure you have boot.ipxe script with the minimal configuration.
Use `gentoocd_unpack.sh` to download latest iso and unpack needed files.
If you want to extract them yourself then it ise these files you need
* `/boot/gentoo`
* `/boot/gentoo.igz`
* `/image.squashfs`

## Having Gentoo mirrors host the needed files
Please see issue [#2](/../../issues/2) and https://bugs.gentoo.org/494300

## Setting up your own PXE server
This is TODO, help welcome

## Simple testing
To test pcbios boot you can try `test_w_qemu.sh useonline`
See [#4](/../../issues/4)
