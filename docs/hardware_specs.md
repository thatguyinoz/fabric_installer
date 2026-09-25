# Hardware and Virtual Machine Specifications

This document outlines the recommended hardware sizing, virtual machine (VM) configurations, and operating system requirements for running [Daniel Miessler's Fabric](https://github.com/danielmiessler/fabric) effectively and reproducibly.

---

## 1. Operating System Recommendations

- **Primary & Preferred OS**: **Debian 13 (Trixie)**
  - Debian provides a rock-solid, lightweight, and predictable environment ideal for reproducible automation, background services, and VM deployments.
- **Secondary / Compatibility Targets**:
  - Debian 12 (Bookworm)
  - Ubuntu 24.04 LTS / 22.04 LTS

---

## 2. Hardware & Virtual Machine Sizing Tiers

Choose the deployment tier that matches your expected workload:

| Specification | Tier 1: Cloud VPS (API-Only) | Tier 2: Fabric VM + Svelte Web App (Primary Default) | Tier 3: Media & Power User VM | Tier 4: Colocated Local Inference |
|---|---|---|---|---|
| **Primary Workload** | CLI only, cloud LLM APIs | **Fabric CLI + REST API (`fabric --serve`) + Svelte Web App + LAN Ollama** | Fabric + Svelte Web App + Audio/Video tools (`--av-ingest`) | Fabric + Local Ollama installed on same host |
| **vCPU / Cores** | 1 – 2 vCPU | **2 vCPU** | 2 – 4 vCPU | 4 – 8+ vCPU (AVX2 required) |
| **System RAM** | 2 GB | **2 – 4 GB** (Accommodates Go daemon + Node.js Svelte GUI) | 4 – 8 GB | 16 – 32 GB+ (for local model weights) |
| **Storage (Disk)** | 20 GB SSD | **25 – 30 GB SSD** | 50 GB NVMe / SSD | 100 – 200 GB+ NVMe SSD |
| **GPU / VRAM** | Not required | **Not required** (Inference handled by LAN server) | Not required | NVIDIA GPU with 8 GB+ VRAM |
| **Network** | 100 Mbps internet | **Gigabit LAN** (Ollama port 11434, Web GUI 5173, API 8080) | 1 Gbps internet | 1 Gbps internet |

---

## 3. Network Ports & Firewall Configuration

When deploying on a headless Debian 13 VM, ensure your firewall permits traffic on the following ports:

| Port | Protocol | Purpose | Access Scope |
|---|---|---|---|
| **5173** | TCP | Fabric Svelte Web App (Frontend GUI) | LAN / Browser access |
| **8080** | TCP | Fabric REST API Server (`fabric --serve`) | Localhost / LAN |
| **11434** | TCP | Remote Ollama API (Outbound connection from VM to LAN host) | Internal LAN only |

---

## 4. Virtual Machine & Hypervisor Configuration

When provisioning Debian 13 inside a hypervisor, apply the following optimizations:

### Proxmox VE (KVM)
- **OS Type**: Linux (Kernel 6.x+)
- **CPU**: Set CPU Type to `host` to expose host CPU flags (crucial for Go runtime performance and tool compilation).
- **Memory**: Minimum 2048 MB (4096 MB recommended with Svelte Web App) with ballooning enabled.
- **Disk**: VirtIO SCSI with `IOThread` enabled, `Discard` (TRIM) turned on.
- **Network**: VirtIO (paravirtualized).
- **GPU Passthrough (Optional, Tier 4 only)**: PCIe passthrough for NVIDIA GPUs with IOMMU enabled in host BIOS/GRUB.

### VMware ESXi / Workstation
- **Guest OS**: Debian GNU/Linux 12/13 (64-bit).
- **Compatibility**: Hardware version 19 or later.
- **CPU**: Enable "Expose hardware assisted virtualization to guest OS" (VT-x/AMD-V) and "Virtualize CPU performance counters".
- **Disk**: VMware Paravirtual SCSI (PVSCSI) with SSD emulation enabled.

### QEMU / KVM (virt-manager / libvirt)
- **Chipset**: Q35 with UEFI (OVMF) firmware.
- **CPU**: Model `host-passthrough`.
- **Disk**: VirtIO Block or VirtIO SCSI.
- **Graphics**: Headless console (`serial` or SPICE) for server installations.

### Microsoft Hyper-V / WSL2
- **Hyper-V Generation**: Generation 2 (UEFI, Secure Boot with "Microsoft UEFI Certificate Authority").
- **Dynamic Memory**: Enabled with minimum 2 GB and maximum matching your tier.
- **WSL2**: Debian 13 can run inside WSL2 on Windows 11; ensure `.wslconfig` allocates adequate RAM (`memory=4GB` or `8GB`) and swap.

---

## 5. System Prerequisites & Component Stack

The default installation stack provisions:
- **Core Toolchain**: `curl`, `git`, `jq`, `tar`, `gzip`, `build-essential`.
- **Go Runtime**: Go 1.22+ (system `/usr/local/go` or user `~/.local/go`).
- **Fabric Core**: Go binary (`fabric`) and REST API daemon (`fabric --serve`).
- **Svelte Web App**: Node.js 20 LTS and pnpm/npm.
- **Background Daemons**: `systemd` service units (`fabric.service` on port 8080 and `fabric-web.service` on port 5173).

### Optional Addon: Audio/Video Ingestion (`--av-ingest`)
For media analysis and YouTube transcript extraction, pass the `--av-ingest` flag:
- `ffmpeg` (for audio extraction and conversion)
- `yt-dlp` (for YouTube transcript downloading)

---

## 6. Connecting Fabric VM to a LAN Ollama Instance (Client Setup)

When deploying Fabric in a VM that connects to an existing Ollama instance on your local network:

1. **Client Footprint**: The Debian 13 VM acts purely as the CLI orchestrator, REST API host, and web dashboard. It does not store GGUF model weights or require local GPU resources.
2. **Environment Configuration**:
   - Point Fabric to your LAN Ollama server by setting `OLLAMA_BASE_URL`:
     ```bash
     export OLLAMA_BASE_URL="http://<LAN_OLLAMA_IP>:11434"
     ```
   - Alternatively, specify the LAN URL when prompted during initial setup (`fabric --setup`).
3. **Network Connectivity Verification**:
   - Confirm that the Fabric VM can reach the Ollama server:
     ```bash
     curl -s http://<LAN_OLLAMA_IP>:11434/api/tags | jq .
     ```
   - A successful response will return a JSON list of models available on your LAN Ollama server.
