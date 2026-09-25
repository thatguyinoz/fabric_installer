# Hardware and Virtual Machine Specifications

This document outlines the recommended hardware sizing, virtual machine (VM) configurations, and operating system requirements for running [Daniel Miessler's Fabric](https://github.com/danielmiessler/fabric) effectively and reproducibly.

---

## 1. Operating System Recommendations

- **Primary & Preferred OS**: **Debian 13 (Trixie)**
  - Debian provides a rock-solid, lightweight, and predictable environment ideal for reproducible automation and server deployment.
- **Secondary / Compatibility Targets**:
  - Debian 12 (Bookworm)
  - Ubuntu 24.04 LTS / 22.04 LTS

---

## 2. Hardware & Virtual Machine Sizing Tiers

Choose the deployment tier that matches your expected workload:

| Specification | Tier 1: Cloud VPS (API-Only) | Tier 2: Fabric VM with LAN Ollama (Primary Use Case) | Tier 3: Power User / Media VM | Tier 4: Colocated Local Inference |
|---|---|---|---|---|
| **Primary Workload** | Cloud LLM APIs only | **Fabric on Debian 13 VM connecting to external LAN Ollama server** | Fabric + YouTube/Audio tools (`yt-dlp`, `ffmpeg`) | Fabric + Local Ollama installed in the same VM |
| **vCPU / Cores** | 1 – 2 vCPU | **1 – 2 vCPU** | 2 – 4 vCPU | 4 – 8+ vCPU (AVX2 support required) |
| **System RAM** | 2 GB (1 GB min + swap) | **2 – 4 GB** (No model weights in VM RAM) | 4 – 8 GB | 16 – 32 GB+ (for local model weights) |
| **Storage (Disk)** | 20 GB SSD | **20 – 30 GB SSD** (No model files stored in VM) | 40 – 50 GB NVMe / SSD | 100 – 200 GB+ NVMe SSD |
| **GPU / VRAM** | Not required | **Not required** (Inference handled by LAN server) | Not required | NVIDIA GPU with 8 GB+ VRAM |
| **Network** | 100 Mbps (outbound HTTPS) | **Gigabit LAN** (access to Ollama server port 11434) | 1 Gbps (for downloading media) | 1 Gbps (for downloading model weights) |

---

## 3. Virtual Machine & Hypervisor Configuration

When provisioning Debian 13 inside a hypervisor, apply the following optimizations:

### Proxmox VE (KVM)
- **OS Type**: Linux (Kernel 6.x+)
- **CPU**: Set CPU Type to `host` to expose host CPU flags (crucial for Go runtime performance and tool compilation).
- **Memory**: Minimum 2048 MB with ballooning enabled if memory is constrained.
- **Disk**: VirtIO SCSI with `IOThread` enabled, `Discard` (TRIM) turned on.
- **Network**: VirtIO (paravirtualized).
- **GPU Passthrough (Optional, Tier 4 only)**: PCIe passthrough for NVIDIA GPUs with IOMMU enabled in host BIOS/GRUB.

### VMware ESXi / Workstation
- **Guest OS**: Debian GNU/Linux 12/13 (64-bit).
- **Compatibility**: Hardware version 19 or later.
- **CPU**: Enable "Expose hardware assisted virtualization to guest OS" (VT-x/AMD-V) and "Virtualize CPU performance counters" if benchmarking.
- **Disk**: VMware Paravirtual SCSI (PVSCSI) with SSD emulation enabled.

### QEMU / KVM (virt-manager / libvirt)
- **Chipset**: Q35 with UEFI (OVMF) firmware.
- **CPU**: Model `host-passthrough`.
- **Disk**: VirtIO Block or VirtIO SCSI.
- **Graphics**: VirtIO or headless console (`serial` or SPICE) for server installations.

### Microsoft Hyper-V / WSL2
- **Hyper-V Generation**: Generation 2 (UEFI, Secure Boot with "Microsoft UEFI Certificate Authority").
- **Dynamic Memory**: Enabled with minimum 2 GB and maximum matching your tier.
- **WSL2**: Debian 13 can run inside WSL2 on Windows 11; ensure `.wslconfig` allocates adequate RAM (e.g., `memory=4GB` or `8GB`) and swap.

---

## 4. System Prerequisites & Dependencies

Before running the Fabric installer, verify that your Debian 13 installation has basic networking and package manager tools available:

- `curl` or `wget` (for downloading packages)
- `git` (for repository and pattern management)
- `jq` (for JSON output processing)
- `tar` / `gzip` (for Go binary extraction)
- `sudo` / non-root user with administrative privileges

Optional Addon Packages:
- `ffmpeg` (for audio extraction and transcription workflows)
- `yt-dlp` (for YouTube transcript downloading)
- `ollama` (for Tier 4 colocated local execution only; not required when using an existing LAN instance)

---

## 5. Connecting Fabric VM to a LAN Ollama Instance (Client Setup)

When deploying Fabric in a VM that connects to an existing Ollama instance on your local network:

1. **Client Footprint**: The Debian 13 VM acts purely as the CLI orchestrator and pattern pipeline. It does not store GGUF model weights or require local GPU resources.
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
