# Fabric Installer & Deployment Toolkit

An automated, modular, and replicable installation suite for deploying [Daniel Miessler's Fabric](https://github.com/danielmiessler/fabric) on modern Linux environments, with primary support and optimization for **Debian 13 (Trixie)**.

---

## Overview

Fabric is an open-source framework designed to augment humans using AI via modular prompt patterns, context pipelines, and CLI integrations. 

This repository provides reproducible automation scripts, environment setup utilities, hardware sizing guidelines, and addon management to make deploying Fabric seamless across servers, virtual machines, and workstations.

---

## Default Installation Stack (Debian 13 VM)

By default, the installer provisions a full-service environment on the target host:

1. **Fabric Core CLI & REST API Server**:
   - Compiles and installs the latest Fabric binary via Go (`go install github.com/danielmiessler/fabric@latest`).
   - Runs the built-in REST API server (`fabric --serve`) on port `8080`.
2. **Fabric Svelte Web App (Default GUI)**:
   - Modern, responsive web interface built with Svelte + Skeleton UI.
   - Accessible via browser on the LAN at `http://<VM_IP>:5173`.
3. **`systemd` Service Units**:
   - Manages background daemons automatically across reboots (`fabric.service` and `fabric-web.service`).
4. **LAN Ollama Client Integration**:
   - Connects to your existing LAN-accessible Ollama instance via `OLLAMA_BASE_URL` without requiring local GPU or model storage in the VM.

### Alternative Options Announced
The installer supports and announces several optional configurations:
- **Headless Mode (`--no-gui`)**: Deploys CLI and REST API daemon only, omitting Node.js and the Svelte web frontend.
- **Ollama API Compatibility Mode (`--serveOllama`)**: Configures the Fabric daemon to expose standard Ollama API endpoints (`GET /api/tags`, `POST /api/chat`), allowing existing frontends (Open WebUI, AnythingLLM) to point to Fabric.
- **Streamlit Python UI**: Alternative data science and visualization dashboard (`streamlit run web/streamlit.py`).

---

## Optional Media Addon: `--av-ingest`

To enable Fabric's YouTube URL transcript extraction (`fabric -y <url> -p extract_wisdom`) and audio pipelines, pass the `--av-ingest` (or `-a`) flag:
- Installs `ffmpeg` (system package via apt).
- Installs `yt-dlp` (latest release binary).

---

## Operating System & Hardware Sizing

- **Preferred OS**: **Debian 13 (Trixie)** (also compatible with Debian 12 and Ubuntu 22.04/24.04 LTS).

### Sizing Tiers at a Glance

| Deployment Tier | Workload Focus | vCPU | RAM | Storage | Acceleration |
|---|---|---|---|---|---|
| **Tier 1: Cloud VPS** | CLI only, Cloud APIs (OpenAI, Anthropic, Groq) | 1–2 | 2 GB | 20 GB SSD | None |
| **Tier 2: Fabric VM + Web GUI (Default)** | Fabric CLI + REST API + Svelte Web App + LAN Ollama | 2 | 2–4 GB | 25–30 GB SSD | None (Remote GPU) |
| **Tier 3: Media & Power User** | Fabric + Svelte Web App + Audio/Video (`--av-ingest`) | 2–4 | 4–8 GB | 50 GB SSD | None |
| **Tier 4: Colocated Local Inference** | Local Ollama + Fabric on same host | 4–8 | 16–32 GB | 100+ GB NVMe | NVIDIA GPU (8GB+ VRAM) |

> For hypervisor configurations (Proxmox VE, VMware, KVM, WSL2) and network firewall settings, see [docs/hardware_specs.md](docs/hardware_specs.md).

---

## Architecture & Modules

- **Dependency Validator**: Verifies and installs core build tools (`curl`, `git`, `jq`, `tar`, `gzip`, `build-essential`).
- **Go Toolchain Provisioner**: Detects existing Go installations or automates installation of official Go 1.22+ runtime.
- **Fabric Binary Installer**: Builds Fabric via Go (`go install github.com/danielmiessler/fabric@latest`).
- **Environment & Shell Setup**: Exports `GOPATH`, `GOBIN`, `OLLAMA_BASE_URL`, and Fabric binaries into PATH across `~/.bashrc` and `~/.zshrc`.
- **Systemd Integration**: Provisions background service units for continuous LAN availability.
- **Svelte Web App Provisioner**: Sets up Node.js LTS and deploys the Svelte web frontend.
- **Audio/Video Ingest (`--av-ingest`)**: Installs `ffmpeg` and `yt-dlp`.

---

## Directory Structure

```
.
├── docs/
│   └── hardware_specs.md            # Sizing guidelines & hypervisor configs
├── scripts/                         # Versioned release scripts (source of truth)
│   ├── fabric-installer-v0.1.0.sh   # Initial dependency validator
│   ├── fabric-installer-v0.2.0.sh   # Go toolchain provisioner
│   └── fabric-installer-v0.3.0.sh   # Active release: Fabric binary & dry-run engine
├── install.sh                       # Production release copy (mirrored from scripts/)
├── project_workflow.md              # Project conventions and release workflow
├── function_integration_workflow.md # Isolated function development workflow
├── script_style_guide.md            # Shell scripting style standards
├── status.md                        # Current status and phase tracking
├── TODO.md                          # Actionable roadmap
├── Disclaimer.md                    # Humorous disclaimer of liability
└── README.md                        # Project documentation
```

---

## Development & Contribution Workflow

This project adheres to an isolated function development workflow with a strict **Host Safety Mandate**:
1. Develop individual helper functions in standalone `temp_<feature>.sh` scripts.
2. Test non-invasively via static analysis (`bash -n`) and `--dry-run` simulation modes.
3. Integrate verified code into versioned scripts under `scripts/`.
4. Deploy tested releases to the root `install.sh`.

See [project_workflow.md](project_workflow.md) and [function_integration_workflow.md](function_integration_workflow.md) for full details.

---

## License

This project is licensed under the MIT License.

---

## Disclaimer

> 🛸 **Notice**: This project is an independent community toolkit provided "as-is". Before proceeding, please review our [Disclaimer](Disclaimer.md) for important details regarding API costs, shell execution, and sanity preservation.
