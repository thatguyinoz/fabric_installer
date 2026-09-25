# Project Roadmap & TODO

## Phase 1: Planning & Specifications
- [ ] Define hardware & VM sizing guidelines (cloud VPS, desktop VM, bare metal, GPU/Ollama considerations)
- [ ] Draft initial `README.md` structure with requirements and installation guide
- [ ] Create `scripts/` directory structure for versioned scripts

## Phase 2: Core Installation Functions (Isolated Development)
- [ ] `temp_check_deps.sh`: System requirements and package dependency checks (curl, git, jq, etc.)
- [ ] `temp_install_go.sh`: Automated Go toolchain installation / verification
- [ ] `temp_install_fabric.sh`: Fabric installation routine (`go install github.com/danielmiessler/fabric@latest` or prebuilt releases)
- [ ] `temp_configure_env.sh`: PATH setup and shell profile persistence (`~/.bashrc`, `~/.zshrc`)

## Phase 3: Addons & Configuration
- [ ] `temp_configure_keys.sh`: Interactive API key setup (OpenAI, Anthropic, Groq, Ollama, etc.)
- [ ] `temp_install_addons.sh`: Optional dependencies (Ollama for local LLMs, ffmpeg, yt-dlp for media processing)
- [ ] `temp_verify_install.sh`: Health check & pattern synchronization (`fabric --update`)

## Phase 4: Integration & Packaging
- [ ] Assemble version 0.1.0 into `scripts/fabric-installer-v0.1.0.sh`
- [ ] Create root deployment script `install.sh`
- [ ] Validate end-to-end installation across target environments
- [ ] Complete `README.md` documentation
