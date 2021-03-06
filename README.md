# [Gentoo-iPXE](https://github.com/NiKiZe/Gentoo-iPXE)
Example on Minimal Gentoo PXE boot with focus on using [iPXE](http://ipxe.org)

[![iPXE booting Gentoo sample screen](https://b800.org/3hf9U.png)](https://b800.org/3hf9U)

### Background
This is to show and use how Gentoo can be booted over PXE since [Gentoo bug #396467](https://bugs.gentoo.org/396467) was resolved
in [24ad50](https://github.com/gentoo/genkernel/commit/24ad5065fa856389ee9b058f57adffbe752da157)

## Quick start
Quick QEMU test: `qemu-system-x86_64 -enable-kvm -M q35 -m 1024 -cpu host -nic user,model=virtio,tftp=.,bootfile=http://gentoo.ipxe.se/boot.ipxe -boot menu=on -usb`
This uses [iPXE](http://boot.ipxe.org), manual steps:
* Get into the iPXE shell (from PXE boot or even from one of the disk images)
* Get ip `dhcp`
* Start Gentoo `chain http://gentoo.ipxe.se/boot.ipxe`

#### Explanation of ipxe script
If a file is referred to in a iPXE script, and not given as absolute path it tries to load from the "last path"
* `kernel gentoo root=/dev/ram0 init=/linuxrc  dokeymap looptype=squashfs loop=/image.squashfs  cdroot initrd=initrd.magic vga=791` - download gentoo kernel image, and append standard cmdline as seen in isolinux/grub, the initrd= is required for the kernel to find the init file in EFI mode boot
* `initrd combined.igz` - downloads combined.igz into memory - you can give the full path over http or tftp if you want to.
* `boot` - boot

#### Testing
Script to simplify testing: [`test_w_qemu.sh useonline`](test_w_qemu.sh)
See [Issue #4 for more work on EFI](https://github.com/NiKiZe/Gentoo-iPXE/issues/4)

## Having Gentoo mirrors host the needed files
Working on this, See [Gentoo bug #494300](https://bugs.gentoo.org/494300) and [issue #2](https://github.com/NiKiZe/Gentoo-iPXE/issues/2). There is also [forum post](https://forums.gentoo.org/viewtopic-p-8636881.html#8636881)

## Create your own mirror
Grab or create [`boot.ipxe`](boot.ipxe) script with the minimal configuration.
Use [`gentoocd_unpack.sh`](gentoocd_unpack.sh) to download latest iso and unpack needed files.
If you want to extract them yourself then it ise these files you need
* `/boot/gentoo`
* `/boot/gentoo.igz`
* `/image.squashfs`
And finaly create the combined initrd using `(cat boot/gentoo.igz; (echo image.squashfs | cpio -H newc -o)) > combined.igz`

### Setting up your own server
Needed services are BOOTP/DHCP and TFTP. Refer to these services individually.
You might also want to have a HTTP server for better performance.
"PXE server" might refer to the one machine that serves both of these services.
#### TFTP service
Install a simple to use tftp server
```bash
# install atftp
emerge -uv1 net-ftp/atftp
# ensure we have tftp root directory
mkdir -p /tftproot
# add it to startup
rc-update add atftp default
# make sure it is running
/etc/init.d/atftp restart

# move to tftp root directory
pushd /tftproot
# Prepare iPXE files
for i in ipxe.efi snponly.efi undionly.kpxe ipxe.pxe; do wget -nc http://boot.ipxe.org/$i; done

# Optional Prepare Grub
grub-mknetdir --net-directory .

# Optional Prepare pxelinux
emerge -uv1 syslinux
cp /usr/share/syslinux/pxelinux.0 .
cp /usr/share/syslinux/ldlinux.c32 .

# TODO copy over configs for grub/pxelinux

popd
```

#### BOOTP/DHCP service
Use one of these, not both
##### isc-dhcpd
[This configuration](https://gist.github.com/robinsmidsrod/4008017) as a great start for iPXE, [official documentation](https://ipxe.org/howto/chainloading#breaking_the_infinite_loop) can also be helpful.
If you are in control of your DHCP server, then this is the best option.
##### dnsmasq Proxy DHCP mode

If you can not replace your DHCP server then you can instead run [Proxy DHCP](https://ipxe.org/appnote/proxydhcp).
[Full configuration for dnsmasq in proxydhcp mode](https://gist.github.com/NiKiZe/5c181471b96ac37a069af0a76688944d)
```bash
# Disable DNS server
port=0

# Configure proxy mode and interface
dhcp-range=${interface_subnet},proxy
interface=${interface_name}

# Enable PXE menu for non iPXE clients
dhcp-match=set:ipxe-ok,175,19
pxe-service=tag:!ipxe-ok,X86PC,PXE,undionly.kpxe,${tftp_server_ip}
pxe-service=tag:!ipxe-ok,BC_EFI,PXE,snponly.efi,${tftp_server_ip}
pxe-service=tag:!ipxe-ok,X86-64_EFI,PXE,snponly.efi,${tftp_server_ip}

# Send script to valid iPXE clients
dhcp-boot=tag:ipxe-ok,http://gentoo.ipxe.se/boot.ipxe,,0.0.0.1
```

### [Alternative client side CPIO combine](altcombine.ipxe)
Above server side generated `combined.igz` has been used. It is also possible to do this client side.
* `initrd gentoo.igz`
* `kernel gentoo {insert options} initrd=initrd.magic`
* `initrd image.squashfs /image.squashfs`
Last initrd Appends squashfs with CPIO header to the ram data, the second argument tells which name to use in CPIO archive

As mentioned `initrd=` is required in EFI mode, `initrd.magic` is a special file in iPXE EFI since [e5f025](https://github.com/ipxe/ipxe/commit/e5f02551735922eb235388bff08249a6f31ded3d) that combines all initrd files into one CPIO archive, pcbios has done the same concatination for a long time.

### [Different types of combine](combined.ipxe)
* `(cat gentoo.igz; (echo image.squashfs | cpio -H newc -o)) > combined.igz`
  - simplest and fastest boot, ~390M file
* `(cat gentoo.igz; (echo image.squashfs | cpio -H newc -o | xz --check=crc32 -vT0)) > combined.igz`
  - compress squashfs, ~360M file, black screen while kernel decompress these parts
* `(xz -d gentoo.igz -c; (echo image.squashfs | cpio -H newc -o)) | xz --check=crc32 -vT0 > combined.igz`
  - recompress everything, ~359M file, black screen while decompressing

TODO investigate memory usage, what is the best way for the kernel in terms of free memory?

<img src="https://ipv6.b800.org/ipv6.svg" style="height: 1rem; vertical-align:middle; " />
