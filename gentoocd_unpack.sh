#!/bin/bash
FILE=$(wget -q http://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/ -O - | grep -o -e "install-amd64-minimal-\w*.iso" | uniq)
echo "Latest found file on mirror is $FILE"
[[ ! -e "$FILE" ]] && (wget -c http://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal/$FILE || exit 1)

# check for iso
srciso=install-amd64-minimal-*.iso
for f in $srciso; do
  srciso=$f
done
echo Using $srciso as source

ALLPOSITIONAL=()
POSITIONAL=()
KEYMAP=se
mksquashoptions=""
while (($#)); do
  ALLPOSITIONAL+=("$1") # save it in an array for later
  case $1 in
  *)
    # unknown arguments are passed thru
    POSITIONAL+=("$1") # save it in an array for later
  ;;
  esac
  shift
done
set -- "${POSITIONAL[@]}" # restore positional parameters
ALLPOSITIONAL=${ALLPOSITIONAL[@]}

echo emerge -uv1 cdrtools
set -x
[ ! -d gentoo_boot_cd ] && (mkdir gentoo_boot_cd || exit 1)
cd gentoo_boot_cd || exit 1
# 7z x is broken in version 16.02, it does work with 9.20
# use isoinfo extraction from cdrtools instead
echo "Extracting iso"
isoinfo -R -i ../$srciso -X || exit 1
echo "Moving out needed files"
mv -v image.squashfs ..
mv -v boot/gentoo ..
mv -v boot/gentoo.igz ..
set +x
kernel=$(grep gentoo grub/grub.cfg | grep root | grep -v docache | sed "s/^.*\/boot\/gentoo /gentoo /")
echo -e "Official kernel cmdline:\n $kernel"
cd ..
rm -rf gentoo_boot_cd
ipxekernel=$(grep "kernel gentoo " boot.ipxe | sed "s/^.*kernel gentoo /gentoo /")
echo -e "Checking for cmdline in boot.ipxe:\n $ipxekernel"
grep -q "$kernel" boot.ipxe && echo " - Looks good"
