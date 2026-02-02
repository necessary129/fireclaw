#!/bin/bash

# Init flow:
# - Copy the ubuntu installation in the image (rootfs) to /data, if /data/.installed is not present
# - Create /data/.installed after installation finishes
# - chroot /data and start openclaw: `openclaw gateway`

set -e

if [ ! -f /data/.installed ]; then
    echo "Installing fireclaw..."
    for dir in /*; do
        case "$dir" in
            /dev|/proc|/sys|/run|/tmp|/data)
                ;;
            *)
                cp -a "$dir" /data/
                ;;
        esac
    done
    mkdir -p /data/dev /data/proc /data/sys /data/run /data/tmp
    touch /data/.installed
    echo "Installation complete."
fi

mkdir -p /data/oldroot

mount --rbind /dev /data/dev
mount --rbind /proc /data/proc
mount --rbind /sys /data/sys

cd /data
pivot_root . oldroot

umount -l /oldroot
rmdir /oldroot

if [ ! -f "/root/.openclaw/openclaw.json" ]; then
    echo "Starting onboard..."
    /usr/bin/openclaw onboard
fi

echo "Starting openclaw gateway..."
exec /usr/bin/openclaw gateway
