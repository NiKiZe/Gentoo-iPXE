#!/bin/bash
echo $0 Got arguments: $*
bootfile="combined.ipxe"

USEEFI=""
VNC="-vnc 127.0.0.1:22"
VGA=""
efibios=""
direct=("-boot" "menu=on")
POSITIONAL=()
while (($#)); do
  case $1 in
  useefi)
    USEEFI=YES
    # >=sys-firmware/edk2-ovmf-202008
    efibios="-bios /usr/share/edk2-ovmf/OVMF_CODE.fd"
    # TODO fix proper chain
    [ -f ipxe.efi ] || wget http://boot.ipxe.org/ipxe.efi
    bootfile="ipxe.efi"
  ;;
  serial)
    echo "using -nographic, Ctrl+A, X exits"
    VNC=""
    VGA="-nographic"
  ;;
  useonline)
    # iPXE which is default in qemu, supports http boot
    bootfile="http://gentoo.ipxe.se/$bootfile"
  ;;
  direct)
    direct=("-kernel" "gentoo" "-initrd" "combined.igz" "-append" "root=/dev/ram0 init=/linuxrc  dokeymap looptype=squashfs loop=/image.squashfs  cdroot")
    bootfile=""
  ;;
  *)
    POSITIONAL+=("$1") # save it in an array for later
  ;;
  esac
  shift
done
set -- "${POSITIONAL[@]}" # restore positional parameters

#VGA="-nographic -device sga"
#VGA="-nographic"
#VGA="-curses"
[[ "$USEEFI" != "YES" ]] && [[ "$VGA" == "" ]] && VGA="-vga vmware"

[[ "$VNC" != "" ]] && (sleep 3; vncviewer :22) &

netscript="-nic user,model=virtio,tftp=.,bootfile=$bootfile"


set -x
jn=$(nproc)
qemu-system-x86_64 -enable-kvm -M q35 -m 2048 -cpu host -smp $jn,cores=$jn,sockets=1 -name lxgentoopxetest \
$netscript \
-watchdog i6300esb -watchdog-action reset \
"${direct[@]}" -usb ${VGA} ${VNC} \
${efibios} \
$POSITIONAL
