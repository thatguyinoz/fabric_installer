# Fabric Installer & Deployment Toolkit: Project Workflow

## 1. Project Overview
- **Project Name**: Fabric Installer & Deployment Toolkit
- **High-Level Summary**: A modular, replicable installation toolkit and documentation suite for deploying Daniel Miessler's Fabric, including automated bash installation scripts, environment configuration, hardware/VM sizing guidelines, and addon management.
- **Core Features**:
  - Automated dependency verification & installation (Go toolchain, Git, curl, jq, optional: ffmpeg, yt-dlp, Ollama).
  - Fabric binary installation/build options (`go install` vs pre-compiled releases) and path setup.
  - Interactive/unattended configuration of AI provider API keys and default models.
  - VM & hardware sizing recommendations (minimal cloud VPS vs local inference workstations).
  - Health checks, pattern updates (`fabric --update`), and verification routines.
- **Technology Stack**: Bash (POSIX-compliant / Bash 4+), Go runtime, systemd/cron (optional updates), Markdown.

## 2. Development Workflow: Isolated Function Development
1. **Isolated Functions**: Develop new helper functions (e.g., dependency check, Go installer, key configuration) in standalone `temp_<function_name>.sh` scripts with `chmod +x`.
2. **Testing**: Validate standalone scripts with various flags and error conditions before integration.
3. **Integration**: Merge proven functions into the active script under `scripts/fabric-installer-vX.XX.sh`.
4. **Cleanup**: Remove temporary `temp_*.sh` scripts upon verification.

## 3. Script Style & Standards
- Adhere to `script_style_guide.md`:
  - Header with shebang (`#!/bin/bash`), metadata, script name, version, and changelog.
  - Modular functions with uppercase global constants and lowercase local variables.
  - Robust error handling (`set -euo pipefail` where appropriate), clean CLI argument handling (`getopts`), and clear `usage()` output.
  - Colorized, descriptive log helpers (`log_info`, `log_warn`, `log_error`, `log_success`).

## 4. Versioning and Release Workflow (Copy Method)
1. **Source of Truth**: Maintain all versioned scripts in `scripts/` (e.g., `scripts/install-fabric-v0.1.0.sh`).
2. **Root Script**: The root script `install.sh` is the user-facing release copy; never edit it directly.
3. **Release Progression**:
   - Increment copy in `scripts/` (e.g., `cp scripts/install-fabric-v0.1.0.sh scripts/install-fabric-v0.2.0.sh`).
   - Implement, update changelog in the header, and test.
   - Deploy to root (`cp scripts/install-fabric-vX.X.X.sh install.sh`).
   - Stage, commit, and document in `status.md` and `README.md`.

## 5. Documentation & Hardware Guides
- Maintain hardware/VM specification matrices directly in `README.md` (or a dedicated `docs/hardware_specs.md`).
- Keep `status.md` and `TODO.md` updated as features and guides are added.

## 6. Tooling Configuration
### File Visibility
To ensure all project files are visible during interactions, especially documentation and configuration files that might be excluded by default, use the `respect_git_ignore=False` flag with file listing and searching tools.
