#!/bin/bash
echo -e "<!doctype html>\n<html>"
echo -e "<head><title>Gentoo minimal livecd over PXE, iPXE prefered</title>"
echo -e "<meta charset=\"utf-8\"><meta name=viewport content=\"width=device-width, initial-scale=1\">"
echo -e "</head><body>"
echo 'See <a href="https://github.com/NiKiZe/Gentoo-iPXE">Gentoo iPXE on GitHub</a>'
echo "<pre style=\"overflow:auto\">"
thisscript=$(basename "$0")
#FILES="gentoo gentoo.igz combined.igz image.squashfs *.iso $(git ls-files)"
readarray -d '' files < <(printf '%s\0' gentoo gentoo.igz combined.igz image.squashfs *.iso $(git ls-files) | sort -zV)
for f in "${files[@]}"; do
[ $f == .gitignore ] && continue
[ $f == $thisscript ] && continue

fsize=$(numfmt --to=iec --suffix=B --padding=6 $(stat --printf="%s" $f))
fdate=$(stat --printf="%.19y" $f)
if [ $f == README.md ]; then
  echo "$fsize $fdate $f"
elif file -b $f | grep -q ASCII; then
  echo "$fsize $fdate <a href=\"$f\">$f</a>"
else
  echo "$fsize $fdate $f"
fi

done
echo "</pre>"
markdown2 README.md || >&2 echo README.md conversion failed, emerge dev-python/markdown2 https://github.com/trentm/python-markdown2