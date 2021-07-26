#!/bin/bash
DISTMIRROR=http://distfiles.gentoo.org
DISTBASE=${DISTMIRROR}/releases/amd64/autobuilds/current-install-amd64-minimal/
FILE=$(wget -q $DISTBASE -O - | grep -o -e "install-amd64-minimal-\w*.iso" | uniq)
wget -c $DISTBASE$FILE || exit 1

# check for iso
srciso=install-amd64-minimal-*.iso
for f in $srciso; do
  srciso=$f
done
echo Using $srciso as source

echo emerge -uv1 app-cdr/cdrtools
set -x
[ ! -d gentoo_boot_cd ] && (mkdir gentoo_boot_cd || exit 1)
cd gentoo_boot_cd || exit 1
# 7z x is broken in version 16.02, it does work with 9.20
# use isoinfo extraction from cdrtools instead
echo "Extracting iso"
isoinfo -R -i ../$srciso -X || exit 1
echo "Moving out needed files"
(!(cmp boot/gentoo.igz ../gentoo.igz) || !(cmp image.squashfs ../image.squashfs)) && \
(cat boot/gentoo.igz; (echo image.squashfs | cpio -H newc -o)) > ../combined.igz
mv -vf image.squashfs ..
mv -vf boot/gentoo ..
mv -vf boot/gentoo.igz ..
set +x
kernel=$(grep gentoo grub/grub.cfg | grep root | grep -v docache | sed "s/^.*\/boot\/gentoo /gentoo /")
echo -e "Official kernel cmdline:\n $kernel"
cd ..
rm -rf gentoo_boot_cd
ipxekernel=$(grep "kernel gentoo " boot.ipxe | sed "s/^.*kernel gentoo /gentoo /")
echo -e "Checking for cmdline in boot.ipxe:\n $ipxekernel"
grep -q "$kernel" boot.ipxe && echo " - Looks good"

# regenerate index
sh gen_html_index.sh > index.html
