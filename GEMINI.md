# Project Mandates

- **STARTUP**:
    1. Use file listing and search tools with "respect_git_ignore=False" and a glob pattern like '**/*' to get a list of all files in the current directory, including those ignored by .gitignore. This provides complete context.
    2. Review the core project documentation: `project_workflow.md`, `function_integration_workflow.md`, `script_style_guide.md`, `status.md`, `TODO.md`, and `README.md`.
    3. Follow the development workflow outlined in `project_workflow.md` and `function_integration_workflow.md`.

- **HOST SAFETY & DEVELOPMENT MANDATE**:
    1. **Do NOT install packages or tools on THIS host**: This development environment is strictly an authoring, testing, and packaging workspace. Never run destructive or system-modifying installation commands (`apt-get install`, `/usr/local/go` mutations, package installations) on this development system.
    2. **Target Deployment**: The scripts in this toolkit are designed to execute on target machines (specifically Debian 13 VMs) or deployed remotely over SSH (future feature).
    3. **Local Validation**: Test scripts on this host strictly via static analysis (`bash -n`), argument verification, and non-mutating `--dry-run` / `--check` simulation modes.

- **REPOSITORY & ENVIRONMENT CONFIGURATION**:
    1. **Repository**: Public repository at `https://github.com/thatguyinoz/fabric_installer.git`.
    2. **Target OS**: Primary preferred operating system for target VMs is **Debian 13 (Trixie)**.

- **IMPORTANT**:
    1. Always adhere to `project_workflow.md` for the development lifecycle, script standards, versioning copy method, and isolated function development (`temp_*.sh`).
    2. You must always check with the user before editing or deleting any core workflow, style, or status/TODO files to avoid unintended loss of data.
