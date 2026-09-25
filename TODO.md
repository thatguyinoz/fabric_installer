# Project Roadmap & TODO

## Phase 1: Planning & Specifications
- [x] Define hardware & VM sizing guidelines with Debian 13 as primary target (`docs/hardware_specs.md`)
- [x] Establish Host Safety Mandate (never install on development host)
- [x] Draft initial `README.md` structure with requirements and installation guide
- [x] Create `scripts/` directory structure for versioned scripts

## Phase 2: Core Installation Functions (Isolated Development with --dry-run)
- [x] `temp_check_deps.sh`: System requirements and package dependency checks (integrated into v0.1.0)
- [x] `temp_install_go.sh`: Automated Go toolchain resolution, verification, and installation with `--dry-run` (integrated into v0.2.0)
- [x] `temp_install_fabric.sh`: Fabric installation routine (`go install` vs binary release) with `--dry-run` (integrated into v0.3.0)
- [ ] `temp_configure_env.sh`: PATH setup and shell profile persistence (`~/.bashrc`, `~/.zshrc`)

## Phase 3: Addons & Configuration
- [ ] `temp_configure_keys.sh`: Interactive API key setup (OpenAI, Anthropic, Groq, LAN Ollama URL)
- [ ] `temp_install_addons.sh`: Optional dependencies (ffmpeg, yt-dlp) with `--dry-run`
- [ ] `temp_verify_install.sh`: Health check & pattern synchronization (`fabric --update`)

## Phase 4: Integration & Local Packaging
- [x] Assemble version 0.1.0 into `scripts/fabric-installer-v0.1.0.sh` and root `install.sh`
- [x] Assemble version 0.2.0 into `scripts/fabric-installer-v0.2.0.sh` and root `install.sh`
- [x] Assemble version 0.3.0 into `scripts/fabric-installer-v0.3.0.sh` and root `install.sh`
- [ ] Assemble subsequent versions (v0.4.0+) as features are completed
- [ ] Update `README.md` with complete usage guide and single-line curl installation commands

## Phase 5: Remote Deployment Suite (SSH)
- [ ] `deploy-remote.sh`: Script to push and execute the installer onto a remote Debian 13 target host over SSH
- [ ] Remote host prerequisites and verification
