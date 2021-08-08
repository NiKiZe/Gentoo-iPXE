#!/bin/bash
DISTMIRROR=http://distfiles.gentoo.org
DISTBASE=${DISTMIRROR}/releases/amd64/autobuilds/current-install-amd64-minimal/
FILE=$(wget -q $DISTBASE -O - | grep -o -e "install-amd64-minimal-\w*.iso" | uniq)

wget -c $DISTBASE$FILE || exit 1
wget -c $DISTBASE$FILE.DIGESTS.asc || exit 2

isoname=
for f in ${FILE}; do
  isoname=$f
done

# https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Media#Linux_based_verification
#wget -O- https://gentoo.org/.well-known/openpgpkey/hu/wtktzo4gyuhzu8a4z5fdj3fgmr1u6tob?l=releng | gpg --import
# slow:
#gpg --keyserver hkps://keys.gentoo.org --recv-keys 0xBB572E0E2D182910

# Download key if missing
gpg --locate-key releng@gentoo.org
# Verify DIGESTS
gpg --verify $isoname.DIGESTS.asc || exit 2

echo "Verifying SHA512 ..."
# grab SHA512 lines and line after, then filter out line that ends with iso
echo "$(grep -A1 SHA512 $isoname.DIGESTS.asc | grep iso$)" | sha512sum -c || exit 2
echo "Verifying BLAKE2 ..."
# grab BLAK2 lines and line after, then filter out line that ends with iso
blake2line=$(grep -A1 BLAKE2 $isoname.DIGESTS.asc | grep iso$)
# remove /var/tmp*.../ part of filename
echo "${blake2line/\/*\//}" | b2sum -c || exit 2
echo " - Awesome! everything looks good."

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
cp index.html index.bak.html
sh gen_html_index.sh > index.html
diff -u index.bak.html index.html
