#!/bin/bash

set -e
cd "$(dirname $0)"

uname_arch="$(uname -m)"
if [ "$uname_arch" == "x86_64" ]; then
  LOCALARCH=amd64
elif [ "$uname_arch" == "aarch64" ]; then
  LOCALARCH=arm64
else
  echo "Unsupported local arch: $uname_arch"
  exit 1
fi

if [ "$TARGETARCH" = "amd64" ]; then
  echo -n ""
elif [ "$TARGETARCH" = "arm64" ]; then
  echo -n ""
else
  echo "Invalid TARGETARCH" >&2
  exit 1
fi

tag="$(date -u +%Y%m%d)-1"
cd image
docker build --platform "linux/$TARGETARCH" -t fireclaw-image:$tag .
cd ..
container_id=$(docker create "fireclaw-image:$tag")
tempfile=$(mktemp -t fireclaw-image-bake-XXXXXXXX)
rm -f "$tempfile"
docker export $container_id | sqfstar "$tempfile"
docker rm $container_id

rm -rf output
mkdir output

# we use `--platform linux/amd64` for bake build regardless of
# the actual local/target platform because `bake` is special -
# it embeds binaries for all platforms in the same image
docker run --rm \
    -v $tempfile:/rootfs.img:ro -v ./output:/output \
    -v ./host_init.sh:/host_init.sh:ro \
    --entrypoint /opt/bake/bake.$LOCALARCH \
    --platform linux/amd64 \
    ghcr.io/losfair/bake:sha-42fbc25 \
    --input /opt/bake/bake.$TARGETARCH \
    --entrypoint /init.sh \
    --firecracker /opt/bake/firecracker.$TARGETARCH \
    --kernel /opt/bake/kernel.$TARGETARCH \
    --initrd /opt/bake/initrd.$TARGETARCH.img \
    --rootfs /rootfs.img \
    --output /output/fireclaw.$TARGETARCH.elf \
    --init-script /host_init.sh
