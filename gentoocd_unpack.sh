#!/bin/bash
# Some features from /lib/gentoo/functions.sh
declare -- nl=$'\n'
declare -- BRACKET=$'\E[34;01m'
declare -- GOOD=$'\E[32;01m'
declare -- WARN=$'\E[33;01m'
declare -- BAD=$'\E[31;01m'
declare -- NORMAL=$'\E[0m'
declare -- BRBAD="${BRACKET}[ ${BAD}!!${BRACKET} ]${NORMAL}"
declare -- BROK="${BRACKET}[ ${GOOD}ok${BRACKET} ]${NORMAL}"
_indent=
_eprint ()
{
    local color;
    color=$1;
    shift;
    printf ' %s*%s %s%s' "${color}" "${NORMAL}" "${_indent}" "$*";
}
_ewnl ()
{
    test "${nl}" && ! case $1 in
        *"${nl}")
            false
        ;;
    esac
}
ebegin ()
{
    local msg;
    msg=$*;
    while _ewnl "${msg}"; do
        msg=${msg%"${nl}"};
    done;
    _eprint "${GOOD}" "${msg} ...${nl}";
}
eerrorn () { _eprint "${BAD}" "$@" 1>&2; return 1; }
eerror () { eerrorn "${*}${nl}"; }
ewarnn () { _eprint "${WARN}" "$@" 1>&2; }
ewarn () { ewarnn "${*}${nl}"; }
einfon () { _eprint "${GOOD}" "$@"; }
einfo () { einfon "${*}${nl}"; }
set -euo pipefail

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

read -r sqfs_size SOURCE_DATE_EPOCH < <(stat -c "%s %Y" image.squashfs)
(cat gentoo.igz; cpio --reproducible -H newc -o <<< "image.squashfs" | pv -s $sqfs_size) > combined.new.igz
# touch can be used to modify mtime of the combined file, but that is in a way lying so have opted not to
#touch -d "@$SOURCE_DATE_EPOCH" combined.new.igz
unset SOURCE_DATE_EPOCH
#[ gentoo.igz -nt combined.new.igz ] && touch -r gentoo.igz combined.new.igz
# only replace combined.igz if actually changed, to keep timestamps
([ ! -e combined.igz ] || !(cmp -s combined.new.igz combined.igz)) && mv -f combined.new.igz combined.igz
[ -e combined.new.igz ] && rm -f combined.new.igz

grubkernel=$(isoinfo -j UTF-8 -R -i ${isoname} -x /boot/grub/grub.cfg | grep "linux /boot" | grep -v \
 -e docache)

set +x
echo " ... extraction done"
[[ -z "$grubkernel" ]] && eerror "No kernel info from grub.cfg found"
kernel=${grubkernel#*/boot/gentoo }
einfo "Official kernel cmdline:$nl     $kernel"
kernel=${kernel/dokeymap/\$\{keymap\}}
for i in *.ipxe; do
  ipxekernel=$(grep "kernel gentoo " "$i" | sed "s/^.*kernel gentoo /gentoo /")
  einfo "Checking for cmdline in $i:$nl     $ipxekernel"
  grep -q "$kernel" "$i" && echo " - Looks good $BROK" || echo " - Might need update $BRBAD"
done

# regenerate index
cp index.html index.bak.html
sh gen_html_index.sh > index.html
diff -u index.bak.html index.html
