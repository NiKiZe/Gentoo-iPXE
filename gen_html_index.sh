#!/bin/bash
echo -e "<!doctype html>\n<html>"
echo -e "<head><title>Gentoo minimal livecd over PXE, iPXE prefered</title>"
echo -e "<meta charset=\"utf-8\" /><meta name=viewport content=\"width=device-width, initial-scale=1\" />"
echo -e '<link rel="canonical" href="https://gentoo.ipxe.se/" />'
echo -e '<link rel="icon" href="res/favicon.svg" />'
echo '<meta property="og:image" content="https://b800.org/3hf9U.png">'
echo '<style>'
echo 'body { font-family: system-ui; }'
echo 'div, p { max-width: 99%; overflow: auto; }'
# https://github.com/richleland/pygments-css/blob/master/default.css
echo 'code { background: #f0f0f0; overflow-wrap: anywhere; }'
echo '.codehilite { background: #f0f0f0; margin 0.1em }'
echo '.codehilite .k { color: #008000; font-weight: bold } /* Keyword */'
echo '.codehilite .o { color: #666666 } /* Operator */'
echo '.codehilite .p { color: #101010 } /* Punctuation */'
echo '.codehilite .c1 { color: #408080; font-style: italic } /* Comment.Single */'
echo '.codehilite .nb { color: #008000 } /* Name.Builtin */'
echo '.codehilite .nv { color: #19177c } /* Name.Variable */'
echo '@media (prefers-color-scheme: dark) {'
echo '  body {'
echo '    color: #ccc;'
echo '    background: #121212;'
echo '  }'
echo '  a {color: #809fff;}'
echo '  code, .codehilite { background: #232323; }'
echo '  .codehilite .p { color: #404040 } /* Punctuation */'
echo '  .codehilite .nv { color: #1917fc } /* Name.Variable */'
echo '}'
echo '</style>'
echo -e "</head><body>"
markdown2 -x fenced-code-blocks README.md || >&2 echo README.md conversion failed, emerge dev-python/markdown2 https://github.com/trentm/python-markdown2
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
echo '<link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/highlight.js/11.2.0/styles/default.min.css">'
#-x highlightjs-lang
#echo '<script src="//cdnjs.cloudflare.com/ajax/libs/highlight.js/11.2.0/highlight.min.js"></script>'
#echo '<script>hljs.highlightAll();</script>'
