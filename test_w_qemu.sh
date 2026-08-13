#!/bin/bash
echo $0 Got arguments: $*
bootfile="combined.ipxe"

USEEFI=""
VNC="-vnc 127.0.0.1:22"
VGA=""
efibios=""
memorygb=2
POSITIONAL=()
while (($#)); do
  case $1 in
  useefi)
    USEEFI=YES
    cp /usr/share/edk2-ovmf/OVMF_VARS.fd kvm_lxgentootest_VARS.fd
    efibios="-drive if=pflash,unit=0,format=raw,readonly=on,file=/usr/share/edk2-ovmf/OVMF_CODE.fd \
      -drive if=pflash,unit=1,format=raw,file=kvm_lxgentootest_VARS.fd"
    cp $bootfile autoexec.ipxe
    [ -f ipxe.efi ] || (wget https://boot.ipxe.org/x86_64-efi/ipxe-legacy.efi && mv ipxe-legacy.efi ipxe.efi)
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
    # TODO add warning if online and serial since there will be no console
  ;;
  direct)
    # TODO if serial add console
    POSITIONAL+=("-kernel" "gentoo" "-initrd" "combined.igz" "-append" "dokeymap looptype=squashfs loop=/image.squashfs cdroot")
    bootfile=""
  ;;
  -m)
    shift
    echo "Set memory to $1 gb"
    memorygb=$1
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
if [[ -z "$VNC" ]]; then
  # if serial make sure autoexec.ipxe is set for serial console
  [[ "$USEEFI" != "YES" ]] && cp $bootfile autoexec.ipxe && bootfile="autoexec.ipxe"
  sed -i 's/ cdroot/ cdroot console=ttyS0,115200/' autoexec.ipxe
  sed -i 's/vga=791//' autoexec.ipxe
fi

netscript="-nic user,model=virtio,tftp=.,bootfile=$bootfile"


set -x
jn=$(($(nproc)/2))
qemu-system-x86_64 -enable-kvm -M q35 -m $(($memorygb*1024)) -cpu host -smp $jn,cores=$jn,sockets=1 -name lxgentootest \
$netscript \
-device i6300esb -action watchdog=reset \
-device virtio-rng-pci \
-usb ${VGA} ${VNC} \
${efibios} \
$*
