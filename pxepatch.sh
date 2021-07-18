
if [[ -e "/image.squashfs" ]]; then
# if the requested squashfs file already exists on filesystem
# we say that everything is good and disables the cd detection and mount

got_good_root=1
bootstrapCD() {
    CDROOT_PATH=/
    cd /
    REAL_ROOT=/
    return 0
}

fi