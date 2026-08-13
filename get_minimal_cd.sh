#!/bin/bash
set -euo pipefail
DISTMIRROR=http://distfiles.gentoo.org
DISTBASE=${DISTMIRROR}/releases/amd64/autobuilds/current-install-amd64-minimal/
TRUSTKEY=${TRUSTKEY:-ABD00913019D6354BA1D9A132839FE0D796198B1}

GPGHOME=
[[ -d /etc/portage/gnupg ]] && getuto || true
[[ -d /etc/portage/gnupg ]] && GPGHOME="--homedir /etc/portage/gnupg --no-permission-warning --lock-never --no-random-seed-file --no-auto-key-retrieve --no-auto-check-trustdb"

ensure_key_and_minimal() {
  #https://github.com/ASoft-se/Gentoo-HAI/issues/72#issuecomment-2294998781
  curl -L -C - --remote-name-all --parallel \
    https://qa-reports.gentoo.org/output/service-keys.gpg \
    ${DISTBASE}latest-install-amd64-minimal.txt || return 1

  # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Media#Linux_based_verification
  # gpg import, trust starting with Gentoo L1 signing key
  gpg $GPGHOME --locate-key releng@gentoo.org || \
  gpg $GPGHOME -q \
    --trusted-key $TRUSTKEY \
    --import service-keys.gpg && rm service-keys.gpg || true

  FILE=$(gpg $GPGHOME \
    -o- \
    --verify latest-install-amd64-minimal.txt | grep -v '^#' | awk '{print $1}') \
    && rm latest-install-amd64-minimal.txt || return 1
}
# Download key if missing
ensure_key_and_minimal

curl -L -C - --parallel --remote-name-all $DISTBASE$FILE $DISTBASE$FILE.DIGESTS $DISTBASE$FILE.asc || exit 2

# Verify DIGESTS
gpg $GPGHOME --verify $FILE.asc || exit 2
gpg $GPGHOME -o- --verify $FILE.DIGESTS | grep -B1 "iso$" | while read -r line; do
  if [[ "$line" =~ "# SHA512" ]]; then
    echo -n "Verifying $line ... "
    read -r hash_line && sha512sum -c <<< "$hash_line" || exit 2
  elif [[ "$line" =~ "# BLAKE2" ]]; then
    echo -n "Verifying $line ... "
    read -r hash_line && b2sum -c <<< "$hash_line" || exit 2
  else
    echo "Unknown $line"
  fi
done
echo " - Awesome! everything looks good."
