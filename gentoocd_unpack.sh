#!/bin/bash
set -euo pipefail
ebegin() { echo $* ...; }
eerror() { echo ERROR: $*; }
einfo() { echo $*; }
# Always verify script without this source after changes
[[ -f /lib/gentoo/functions.sh ]] && source /lib/gentoo/functions.sh

srciso=install-amd64-minimal-*.iso
for f in $srciso; do
  if [[ ! -e "$f" ]]; then
    eerror "Matching minimal iso not found:"
    echo "   $f"
    echo " please run get_minimal_cd.sh to fetch latest version"
    exit 1
  fi
  isoname=$f
done
einfo "Using $isoname as source"

echo emerge -uv1 app-cdr/cdrtools
ebegin "Extracting parts of iso"
set -x
# use isoinfo extraction from cdrtools
# -X keeps original mtime
mkdir -p isoextract; pushd isoextract
isoinfo -j UTF-8 -R -i ../${isoname} -X -find -path /image.squashfs && mv -vf image.squashfs ..
isoinfo -j UTF-8 -R -i ../${isoname} -X -find -path /boot/gentoo && mv -vf boot/gentoo ..
isoinfo -j UTF-8 -R -i ../${isoname} -X -find -path /boot/gentoo.igz && mv -vf boot/gentoo.igz ..
popd; rm -rf isoextract
(cat gentoo.igz; (echo image.squashfs | cpio -H newc -o)) > combined.new.igz
grubkernel=$(isoinfo -j UTF-8 -R -i ${isoname} -x /boot/grub/grub.cfg | grep "linux /boot" | grep -v docache)
set +x
[[ -z "$grubkernel" ]] && eerror "No kernel info from grub.cfg found"
echo "... extraction done"
# only replace combined.igz if actually changed, to keep timestamps
([ ! -e combined.igz ] || !(cmp -s combined.new.igz combined.igz)) && mv -f combined.new.igz combined.igz
[ -e combined.new.igz ] && rm -f combined.new.igz

kernel=${grubkernel#*/boot/gentoo }
einfo "Official kernel cmdline:\n     $kernel"
kernel=${kernel/dokeymap/\$\{keymap\}}
for i in *.ipxe; do
  ipxekernel=$(grep "kernel gentoo " "$i" | sed "s/^.*kernel gentoo /gentoo /")
  einfo "Checking for cmdline in $i:\n     $ipxekernel"
  grep -q "$kernel" "$i" && echo " - Looks good" || echo " - Might need update"
done

# regenerate index
cp index.html index.bak.html
sh gen_html_index.sh > index.html
diff -u index.bak.html index.html
