#!/bin/bash
echo 'See <a href="https://github.com/NiKiZe/Gentoo-iPXE">Gentoo iPXE on GitHub</a>'
echo "<pre>"
thisscript=$(basename "$0")
#FILES="gentoo gentoo.igz combined.igz image.squashfs *.iso $(git ls-files)"
readarray -d '' files < <(printf '%s\0' gentoo gentoo.igz combined.igz image.squashfs *.iso $(git ls-files) | sort -zV)
for f in "${files[@]}"; do
[ $f == .gitignore ] && continue
[ $f == $thisscript ] && continue

fsize=$(numfmt --to=iec --suffix=B --padding=6 $(stat --printf="%s" $f))
fdate=$(stat --printf="%.19y" $f)
if file -b $f | grep -q ASCII; then
  echo "$fsize $fdate <a href=\"$f\">$f</a>"
else
  echo "$fsize $fdate $f"
fi

done
