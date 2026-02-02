# FireClaw

**Your personal AI assistant in a single binary.**

FireClaw packages [OpenClaw](https://openclaw.ai/) into a portable, sandboxed microVM that runs anywhere with a single command. No containers, no complex setup—just download and run.

Built with [Firecracker](https://firecracker-microvm.github.io/) for lightweight virtualization and [bake](https://github.com/losfair/bake) for single-binary packaging.

## What is this?

FireClaw is the easiest way to run OpenClaw—a personal AI assistant that connects to your messaging apps (WhatsApp, Telegram, Discord, Slack, and more). Instead of installing dependencies, configuring services, or managing containers, you get one executable that boots a complete Linux environment in milliseconds.

```
┌────────────────────────────────────────────────────────┐
│                    fireclaw binary                     │
│  ┌────────────────────────────────────────────────┐    │
│  │              Firecracker microVM               │    │
│  │  ┌─────────────────────────────────────────┐   │    │
│  │  │            Ubuntu + OpenClaw            │   │    │
│  │  │                                         │   │    │
│  │  │   WhatsApp  Telegram  Discord  Slack    │   │    │
│  │  │       ↓         ↓        ↓       ↓      │   │    │
│  │  │            Your AI Agent                │   │    │
│  │  └─────────────────────────────────────────┘   │    │
│  └────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────┘
```

## Features

- **Single binary** — One ~500MB executable contains everything: kernel, filesystem, and OpenClaw
- **Sandboxed** — Runs in an isolated Firecracker microVM with no host access
- **Persistent** — Your data survives restarts via an auto-created disk image
- **Fast** — Boots in under a second on modern hardware
- **Portable** — Supports both AMD64 and ARM64 (including Apple Silicon via virtualization)

## Requirements

- Linux with KVM support (`/dev/kvm` must be accessible)
- For macOS/Windows: Use a Linux VM with nested virtualization enabled

## Quick Start

1. **Download the latest release:**

   ```bash
   # For AMD64 (Intel/AMD)
   curl -LO https://github.com/AFK-surf/fireclaw/releases/latest/download/fireclaw.amd64.elf
   chmod +x fireclaw.amd64.elf

   # For ARM64 (Apple Silicon in Linux VM, AWS Graviton, etc.)
   curl -LO https://github.com/AFK-surf/fireclaw/releases/latest/download/fireclaw.arm64.elf
   chmod +x fireclaw.arm64.elf
   ```

2. **Run it:**

   ```bash
   ./fireclaw.amd64.elf
   ```

   On first run, FireClaw will:
   - Create a 10GB data disk at `~/.fireclaw/data.img`
   - Initialize the Ubuntu environment
   - Start the OpenClaw onboarding wizard

3. **Connect to the VM:**

   ```bash
   ./fireclaw.amd64.elf ssh
   ```

## Usage

```
fireclaw [OPTIONS] [-- ARGS]

Options:
  --disk <path>       Path to data disk image (default: ~/.fireclaw/data.img)
  -c, --cpus <N>      Number of CPUs (default: 2)
  -m, --memory <MB>   Memory in megabytes (default: 2048)
  --                  Pass remaining arguments to the VM

Commands:
  fireclaw ssh        Connect to a running instance via SSH
```

### Examples

```bash
# Run with custom resources
./fireclaw.amd64.elf -c 4 -m 4096

# Use a specific data disk
./fireclaw.amd64.elf --disk /mnt/storage/fireclaw.img

# Connect to your running instance
./fireclaw.amd64.elf ssh
```

## What's Inside

FireClaw bundles:

| Component | Description |
|-----------|-------------|
| **Linux Kernel** | Minimal 6.1 kernel optimized for microVMs |
| **Ubuntu Noble** | Full Ubuntu 24.04 userspace |
| **OpenClaw** | Personal AI gateway with multi-channel support |
| **Firecracker** | Amazon's lightweight VMM for serverless |

## How It Works

FireClaw uses [bake](https://github.com/losfair/bake) to embed an entire bootable system into a single ELF binary:

1. **Build time**: Docker creates an Ubuntu image with OpenClaw pre-installed, which gets converted to a squashfs filesystem and embedded alongside the kernel and Firecracker
2. **Runtime**: The binary extracts components to memory, boots Firecracker, and pivots to a persistent data disk for your configuration and sessions

All VM-to-host communication happens over vsock—no network namespaces or iptables rules required.

## Building from Source

```bash
# Requires: Docker, squashfs-tools

# Build for your current architecture
./build.sh

# Cross-compile for a specific architecture
TARGETARCH=arm64 ./build.sh
TARGETARCH=amd64 ./build.sh

# Output will be in ./output/fireclaw.<arch>.elf
```

## Troubleshooting

### "KVM not available"

FireClaw requires hardware virtualization:

```bash
# Check if KVM is accessible
ls -la /dev/kvm

# If permission denied, add yourself to the kvm group
sudo usermod -aG kvm $USER
# Then log out and back in
```

### Force start without KVM check

```bash
FIRECLAW_FORCE_START=1 ./fireclaw.amd64.elf
```

Note: This will likely fail if KVM truly isn't available, but can help diagnose issues.

## About OpenClaw

[OpenClaw](https://openclaw.ai/) is a personal AI assistant platform that:

- Connects to **13+ messaging channels** including WhatsApp, Telegram, Discord, Slack, and Signal
- Supports **multiple AI models** from Anthropic (Claude) and OpenAI
- Runs **entirely locally** with your data staying on your device
- Includes **60+ skills** for GitHub, calendar, notes, and more

Learn more at [docs.openclaw.ai](https://docs.openclaw.ai/)

## License

MIT License - see [LICENSE](LICENSE) for details.

Copyright 2026 AFK AI, Inc.
