# Project Status

## Current Status: Phase 2 Paused - Ready for Warm Start
- **Date**: 2026-09-25
- **Current State**: Installer version 0.3.0 released (`scripts/fabric-installer-v0.3.0.sh` and root `install.sh`). Documentation updated with default Svelte Web App, systemd daemons, and `--av-ingest` specifications. All ready for warm start.

---

## Accomplished Milestones
- [x] Initial workspace discovery, documentation review, and Git repository initialization.
- [x] Established project-specific workflow (`project_workflow.md`) and updated project mandates (`GEMINI.md`).
- [x] Public GitHub repository configured and verified at `https://github.com/thatguyinoz/fabric_installer.git`.
- [x] Created `docs/hardware_specs.md` specifying Debian 13 as primary target across 4 sizing tiers (including lightweight client VM for LAN Ollama and default Svelte Web App).
- [x] Added `Disclaimer.md` (humorous Hitchhiker's Guide style) and linked footer in `README.md`.
- [x] Created `scripts/` directory for versioned release management.
- [x] Established Host Safety Mandate in `GEMINI.md` and `project_workflow.md` (no installations on development host; mandatory `--dry-run` simulation).
- [x] **v0.1.0**: System dependency validator and apt package management (`scripts/fabric-installer-v0.1.0.sh`).
- [x] **v0.2.0**: Go toolchain provisioner with official API release query, sha256 checksum verification, and `--dry-run` simulation (`scripts/fabric-installer-v0.2.0.sh`).
- [x] **v0.3.0**: Fabric AI binary resolution (`go install github.com/danielmiessler/fabric@latest`), GitHub release queries, and complete end-to-end `--dry-run` simulation (`scripts/fabric-installer-v0.3.0.sh`).
- [x] Updated specifications: default Svelte Web App, background systemd services (`fabric.service`, `fabric-web.service`), and optional media ingestion (`--av-ingest`).
- [x] User approved specification for next module: `temp_configure_env.sh`.

---

## 🚀 Warm Start Instructions for Next Session
When resuming this workspace, proceed immediately with the approved module:

1. **Immediate Task**: Develop `temp_configure_env.sh` (in isolation with `--dry-run` mode).
2. **Approved Specification**:
   - **Shell Profiles**: Detect and support `~/.bashrc`, `~/.zshrc`, and `~/.profile`.
   - **PATH Persistence**: Export `GOPATH="${HOME}/go"` and `PATH="${GOPATH}/bin:/usr/local/go/bin:${PATH}"`.
   - **LAN Ollama Integration**: Export `OLLAMA_BASE_URL="http://<LAN_OLLAMA_IP>:11434"` (or prompt/flag during install).
   - **Idempotency**: Check for existing markers before appending to prevent duplicate entries.
   - **Host Safety**: Test locally strictly with `--dry-run` to preview the exact shell export blocks without modifying host profile files.
3. **Next Integration Target**: Merge into `scripts/fabric-installer-v0.4.0.sh` and mirror to root `install.sh`.
4. **Subsequent Roadmap (Phase 3)**:
   - `temp_install_av_ingest.sh` (`--av-ingest` for `ffmpeg` and `yt-dlp`).
   - `temp_install_systemd.sh` (`fabric.service` and `fabric-web.service` units).
   - `temp_install_webgui.sh` (Node.js LTS and Svelte Web App build/deploy).
   - Alternative options announcements (Streamlit UI, `--serveOllama`, `--no-gui`).
