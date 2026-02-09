#!/bin/bash

# Init flow:
# - Copy the ubuntu installation in the image (rootfs) to /data, if /data/.installed is not present
# - Create /data/.installed after installation finishes
# - pivot_root to /data and start systemd as PID 1

set -e

# Helper to mount only if not already mounted
mount_if_needed() {
    local fstype="$1"
    local src="$2"
    local dest="$3"
    if ! mountpoint -q "$dest" 2>/dev/null; then
        mount -t "$fstype" "$src" "$dest"
    fi
}

# Mount essential filesystems early (needed for installation)
# These may already be mounted by the initrd
mount_if_needed proc proc /proc
mount_if_needed sysfs sysfs /sys
mount_if_needed devtmpfs devtmpfs /dev
mkdir -p /dev/pts /dev/shm
mount_if_needed devpts devpts /dev/pts
mount_if_needed tmpfs tmpfs /dev/shm

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

    # Generate machine-id for systemd
    if [ ! -f /data/etc/machine-id ] || [ ! -s /data/etc/machine-id ]; then
        cat /proc/sys/kernel/random/uuid | tr -d '-' > /data/etc/machine-id
    fi

    touch /data/.installed
    echo "Installation complete."
fi

# Unmount filesystems before pivot_root (ignore errors if not mounted)
umount /dev/shm 2>/dev/null || true
umount /dev/pts 2>/dev/null || true
umount /dev 2>/dev/null || true
umount /sys 2>/dev/null || true
umount /proc 2>/dev/null || true

mkdir -p /data/oldroot

cd /data
pivot_root . oldroot

# Mount fresh virtual filesystems for systemd
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /dev/pts /dev/shm
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs /dev/shm

# Mount tmpfs for run and tmp
mount -t tmpfs -o mode=755 tmpfs /run
mount -t tmpfs tmpfs /tmp

# Create cgroup2 mount point and mount it
mkdir -p /sys/fs/cgroup
mount -t cgroup2 cgroup2 /sys/fs/cgroup

# Unmount old root (lazy unmount to handle busy mounts)
umount -l /oldroot
rmdir /oldroot

# Ensure machine-id exists
if [ ! -s /etc/machine-id ]; then
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id
fi

# Create necessary runtime directories
mkdir -p /run/systemd /run/dbus /run/user

# Set hostname if not set
if [ ! -s /etc/hostname ]; then
    echo "fireclaw" > /etc/hostname
fi

# Start systemd as PID 1
exec /lib/systemd/systemd --system --show-status=true
