# Fabric Installer & Deployment Toolkit

An automated, modular, and replicable installation suite for deploying [Daniel Miessler's Fabric](https://github.com/danielmiessler/fabric) on modern Linux environments, with primary support and optimization for **Debian 13 (Trixie)**.

---

## Overview

Fabric is an open-source framework designed to augment humans using AI via modular prompt patterns, context pipelines, and CLI integrations. 

This repository provides reproducible automation scripts, environment setup utilities, hardware sizing guidelines, and addon management to make deploying Fabric seamless across servers, virtual machines, and workstations.

---

## Operating System & Hardware Specifications

- **Preferred OS**: **Debian 13 (Trixie)** (also compatible with Debian 12 and Ubuntu 22.04/24.04 LTS).

### Sizing Tiers at a Glance

| Deployment Tier | Workload Focus | vCPU | RAM | Storage | Acceleration |
|---|---|---|---|---|---|
| **Tier 1: Cloud VPS** | Cloud APIs (OpenAI, Anthropic, Groq, etc.) | 1–2 | 2 GB | 20 GB SSD | None |
| **Tier 2: LAN Ollama Client** | Fabric on Debian 13 VM connecting to LAN Ollama | 1–2 | 2–4 GB | 25 GB SSD | None (Remote GPU) |
| **Tier 3: Power User / Media** | Cloud APIs + YouTube/audio transcripts (`yt-dlp`, `ffmpeg`) | 2–4 | 4–8 GB | 50 GB SSD | None |
| **Tier 4: Colocated Local Inference** | Local Ollama + Fabric on same host | 4–8 | 16–32 GB | 100+ GB NVMe | NVIDIA GPU (8GB+ VRAM) or Apple Silicon |

> For comprehensive hypervisor settings (Proxmox VE, VMware, KVM, WSL2) and tuning recommendations, refer to [docs/hardware_specs.md](docs/hardware_specs.md).

---

## Planned Architecture & Modules

The installer is engineered as a modular, POSIX-compliant Bash suite adhering to strict coding and release standards:

- **Dependency Validator**: Verifies and installs core build tools (`curl`, `git`, `jq`, `tar`).
- **Go Toolchain Provisioner**: Detects existing Go installations or automates the installation of an up-to-date Go runtime.
- **Fabric Binary Installer**: Builds Fabric via Go (`go install github.com/danielmiessler/fabric@latest`) or pulls pre-compiled binaries.
- **Environment & Shell Setup**: Correctly exports `GOPATH`, `GOBIN`, and Fabric binaries into PATH across `~/.bashrc` and `~/.zshrc`.
- **Addon Integrations**: Optional one-click configuration for:
  - `ffmpeg` (audio/video processing)
  - `yt-dlp` (YouTube transcript extraction)
  - `ollama` (local model inference)
- **API Key & Configuration Manager**: Interactive configuration helper for API providers and pattern updates (`fabric --update`).

---

## Directory Structure

```
.
├── docs/
│   └── hardware_specs.md            # Sizing guidelines & hypervisor configs
├── scripts/                         # Versioned release scripts (source of truth)
│   └── fabric-installer-v0.1.0.sh   # (Upcoming initial release)
├── install.sh                       # Production release copy (mirrored from scripts/)
├── project_workflow.md              # Project conventions and release workflow
├── function_integration_workflow.md # Isolated function development workflow
├── script_style_guide.md            # Shell scripting style standards
├── status.md                        # Current status and phase tracking
├── TODO.md                          # Actionable roadmap
└── README.md                        # Project documentation
```

---

## Development & Contribution Workflow

This project adheres to an isolated function development workflow:
1. Develop individual helper functions in standalone `temp_<feature>.sh` scripts.
2. Test against target environments (Debian 13).
3. Integrate verified code into versioned scripts under `scripts/`.
4. Deploy tested releases to the root `install.sh`.

See [project_workflow.md](project_workflow.md) and [function_integration_workflow.md](function_integration_workflow.md) for full details.

---

## License

This project is licensed under the MIT License.

---

## Disclaimer

> 🛸 **Notice**: This project is an independent community toolkit provided "as-is". Before proceeding, please review our [Disclaimer](Disclaimer.md) for important details regarding API costs, shell execution, and sanity preservation.

