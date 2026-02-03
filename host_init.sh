#!/bin/bash
set -e

usage() {
    cat <<EOF
Usage: fireclaw [OPTIONS] [-- ARGS...]
       fireclaw ssh   # connect to the currently running fireclaw instance

Options:
  --disk <path>      Mount a disk image at /data. If the file does not exist,
                     a 10G ext4 image will be created (default: ~/.fireclaw/data.img)
  -c, --cpus <N>     Set number of CPUs (default: 2)
  -m, --memory <MB>  Set memory in MB (default: 2048)
  --help             Show this help message

Arguments after -- are passed through to the VM.

To control a running instance, connect to its console with "fireclaw ssh" first:

$ fireclaw ssh
# openclaw pairing approve ...
EOF
    exit "${1:-0}"
}

if [ "$1" = "--help" ]; then
    usage
fi

# Parse arguments
DISK_PATH="$HOME/.fireclaw/data.img"
CPUS=2
MEMORY_MB=2048
BAKE_ARGS=()
PASSTHROUGH_ARGS=()
in_passthrough=0

while [ $# -gt 0 ]; do
    if [ "$in_passthrough" = 1 ]; then
        PASSTHROUGH_ARGS+=("$1")
        shift
        continue
    fi

    case "$1" in
        --help)
            usage
            ;;
        --disk)
            DISK_PATH="$2"
            shift 2
            ;;
        -c|--cpus)
            CPUS="$2"
            shift 2
            ;;
        -m|--memory)
            MEMORY_MB="$2"
            shift 2
            ;;
        --)
            in_passthrough=1
            shift
            ;;
        *)
            BAKE_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ ! -c /dev/kvm ]; then
    echo "⚠️ /dev/kvm does not exist. If running on a VM, ensure that nested virtualization is enabled."
    if [ "$FIRECLAW_FORCE_START" != "1" ]; then
        exit 1
    fi
fi

if [ ! -r /dev/kvm ]; then
    echo "⚠️ /dev/kvm is not accessible to the current user. Please fix permissions."
    if [ "$FIRECLAW_FORCE_START" != "1" ]; then
        exit 1
    fi
fi

if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
    if ! grep -q '\[always\]' /sys/kernel/mm/transparent_hugepage/enabled; then
        echo "⚠️ /sys/kernel/mm/transparent_hugepage/enabled is not set to \"always\". On some machines this can lead to *very* bad performance."
    fi
fi

# Handle disk mount
DISK_MOUNT_ARGS=()
if [ -n "$DISK_PATH" ]; then
    if [ ! -e "$DISK_PATH" ]; then
        mkdir -p "$(dirname "$DISK_PATH")"
        truncate --size 10G "$DISK_PATH.tmp"
        mke2fs -t ext4 -q "$DISK_PATH.tmp"
        mv "$DISK_PATH.tmp" "$DISK_PATH"
    fi
    DISK_MOUNT_ARGS=(-v "$DISK_PATH:/data:ext4")
fi

export BAKE_RUN_VM=1
exec -a fireclaw "$BAKE_EXE" "${BAKE_ARGS[@]}" --cpus "$CPUS" --memory "$MEMORY_MB" "${DISK_MOUNT_ARGS[@]}" "${PASSTHROUGH_ARGS[@]}"
