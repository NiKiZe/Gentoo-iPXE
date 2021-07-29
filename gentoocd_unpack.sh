#!/bin/bash
DISTMIRROR=http://distfiles.gentoo.org
DISTBASE=${DISTMIRROR}/releases/amd64/autobuilds/current-install-amd64-minimal/
FILE=$(wget -q $DISTBASE -O - | grep -o -e "install-amd64-minimal-\w*.iso" | uniq)
wget -c $DISTBASE$FILE || exit 1

# check for iso
isoname=install-amd64-minimal-*.iso
for f in ${isoname}; do
  isoname=$f
done
echo Using ${isoname} as source

echo emerge -uv1 app-cdr/cdrtools
echo "Extracting parts of iso ..."
set -x
# 7z x is broken in version 16.02, it does work with 9.20
# use isoinfo extraction from cdrtools instead
# -X keeps original mtime
isoinfo -R -i ${isoname} -X -find -path /image.squashfs || exit 1
isoinfo -R -i ${isoname} -X -find -path /boot/gentoo && mv -vf boot/gentoo .
isoinfo -R -i ${isoname} -X -find -path /boot/gentoo.igz && mv -vf boot/gentoo.igz .
(cat gentoo.igz; (echo image.squashfs | cpio -H newc -o)) > combined.new.igz
grubkernel=$(isoinfo -R -i ${isoname} -x /grub/grub.cfg | grep "gentoo.* root=" | grep -v docache)
set +x
echo "... extraction done"
# only replace combined.igz if actually changed, to keep timestamps
([ ! -e combined.igz ] || !(cmp -s combined.new.igz combined.igz)) && mv -f combined.new.igz combined.igz
[ -e combined.new.igz ] && rm -f combined.new.igz

kernel=${grubkernel#*/boot/gentoo }
echo -e "Official kernel cmdline:\n $kernel"
kernel=${kernel/dokeymap/\$\{keymap\}}
for i in *.ipxe; do
  ipxekernel=$(grep "kernel gentoo " "$i" | sed "s/^.*kernel gentoo /gentoo /")
  echo -e "Checking for cmdline in $i:\n $ipxekernel"
  grep -q "$kernel" "$i" && echo " - Looks good" || echo " - Might need update"
done

# regenerate index
sh gen_html_index.sh > index.html
