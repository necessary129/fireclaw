FROM ubuntu:noble
RUN apt-get update && apt-get install -y unminimize curl htop unzip chromium-browser python3-pil python3-pip systemd systemd-sysv dbus
RUN yes | unminimize
RUN curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard --no-prompt
COPY ./openclaw.service /etc/systemd/system/openclaw.service
RUN systemctl enable openclaw.service

# Configure serial console for Firecracker (ttyS0)
RUN systemctl enable serial-getty@ttyS0.service

# Mask units that are problematic in VMs/containers
RUN systemctl mask \
    systemd-resolved.service \
    systemd-networkd-wait-online.service \
    systemd-firstboot.service \
    systemd-machine-id-commit.service

# Set a default root password for console access (change this!)
RUN echo 'root:fireclaw' | chpasswd

# Ensure locale is configured
RUN locale-gen en_US.UTF-8 || true

COPY --chmod=755 ./init.sh /init.sh
