#!/bin/bash
# ==============================================================================
# Script Name: fabric-installer.sh
# Description: Automated, modular installer and deployment toolkit for
#              Daniel Miessler's Fabric on Debian 13 (Trixie) and Linux systems.
# Version:     0.3.0
# Author:      thatguyinoz <thatguy@hctech.com.au>
# Repository:  https://github.com/thatguyinoz/fabric_installer
#
# Changelog:
#   v0.3.0 - Added Fabric binary installation module: GitHub release resolution,
#            Go compile/install routine, binary discovery, and dry-run simulation.
#   v0.2.0 - Added Go toolchain module: version checking (>= 1.22.0), official
#            Go release API resolution, sha256 checksum verification, and
#            non-mutating --dry-run simulation.
#   v0.1.0 - Initial foundation: OS detection, architecture resolution,
#            prerequisite dependency checking, and automated apt installation.
# ==============================================================================

set -euo pipefail

# --- Configuration & Setup ---
readonly SCRIPT_NAME="fabric-installer.sh"
readonly VERSION="0.3.0"

# Target Operating System
readonly TARGET_OS_ID="debian"
readonly TARGET_OS_CODENAME="trixie"
readonly TARGET_OS_VERSION="13"

# Go Requirements
readonly MIN_GO_VERSION="1.22.0"
readonly GO_API_URL="https://go.dev/dl/?mode=json"

# Fabric Upstream Configuration
readonly FABRIC_REPO="danielmiessler/fabric"
readonly FABRIC_GO_PKG="github.com/danielmiessler/fabric@latest"
readonly GITHUB_RELEASES_API="https://api.github.com/repos/${FABRIC_REPO}/releases/latest"

# Required system packages
readonly -a REQUIRED_PACKAGES=(
    "curl"
    "git"
    "jq"
    "tar"
    "gzip"
    "build-essential"
)

# Text formatting
if [[ -t 1 ]]; then
    readonly C_RESET="\033[0m"
    readonly C_BOLD="\033[1m"
    readonly C_RED="\033[31m"
    readonly C_GREEN="\033[32m"
    readonly C_YELLOW="\033[33m"
    readonly C_BLUE="\033[34m"
    readonly C_CYAN="\033[36m"
else
    readonly C_RESET=""
    readonly C_BOLD=""
    readonly C_RED=""
    readonly C_GREEN=""
    readonly C_YELLOW=""
    readonly C_BLUE=""
    readonly C_CYAN=""
fi

# --- Logging & Output Helpers ---

log_info() {
    printf "%b[INFO]%b %b\n" "${C_BLUE}" "${C_RESET}" "$*"
}

log_success() {
    printf "%b[SUCCESS]%b %b\n" "${C_GREEN}" "${C_RESET}" "$*"
}

log_warn() {
    printf "%b[WARN]%b %b\n" "${C_YELLOW}" "${C_RESET}" "$*"
}

log_error() {
    printf "%b[ERROR]%b %b\n" "${C_RED}" "${C_RESET}" "$*" >&2
}

log_dryrun() {
    printf "%b[DRY-RUN]%b %b\n" "${C_CYAN}" "${C_RESET}" "$*"
}

# --- Usage & Documentation ---

usage() {
    cat <<EOF
${C_BOLD}Fabric Installer & Deployment Toolkit${C_RESET} (v${VERSION})

Usage: ${SCRIPT_NAME} [OPTIONS]

Options:
  -c, --check           Validate OS, dependencies, Go runtime, and Fabric binary
  -d, --dry-run         Simulate complete installation workflow without modifying system [Safe]
  -i, --install         Run live installation of all components (Target host only)
  -u, --user-space      Install Go to user directory (~/.local/go) instead of /usr/local/go
  -y, --yes             Assume yes to confirmation prompts (non-interactive)
  -v, --version         Display script version and exit
  -h, --help            Display this help message and exit

Examples:
  ./${SCRIPT_NAME} --check
  ./${SCRIPT_NAME} --dry-run
  ./${SCRIPT_NAME} --dry-run --user-space
EOF
}

# --- Environment & OS Detection ---

detect_os() {
    log_info "Detecting operating system..."
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine OS: /etc/os-release not found."
        return 1
    fi

    local os_id os_version_id os_codename os_pretty_name
    os_id="$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')"
    os_version_id="$(grep -E '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"' || true)"
    os_codename="$(grep -E '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"' || true)"
    os_pretty_name="$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"' || echo "Unknown Linux")"

    log_info "OS Detected: ${C_BOLD}${os_pretty_name}${C_RESET} (ID: ${os_id}, Codename: ${os_codename:-N/A})"

    if [[ "${os_id}" == "${TARGET_OS_ID}" && "${os_version_id}" == "${TARGET_OS_VERSION}" ]] || \
       [[ "${os_id}" == "${TARGET_OS_ID}" && "${os_codename}" == "${TARGET_OS_CODENAME}" ]]; then
        log_success "Target OS matched: Debian 13 (Trixie) - Full support."
    elif [[ "${os_id}" == "debian" ]] || [[ "${os_id}" == "ubuntu" ]]; then
        log_warn "Compatible Debian/Ubuntu environment detected (${os_pretty_name}). Supported."
    else
        log_warn "Non-Debian distribution detected (${os_id}). Manual package resolution may be required."
    fi

    return 0
}

detect_arch() {
    local raw_arch="$(uname -m)"
    local mapped_arch

    case "${raw_arch}" in
        x86_64|amd64)
            mapped_arch="amd64"
            ;;
        aarch64|arm64)
            mapped_arch="arm64"
            ;;
        *)
            mapped_arch="${raw_arch}"
            log_warn "Uncommon architecture detected: ${raw_arch}. Some binaries may require compilation."
            ;;
    esac

    echo "${mapped_arch}"
}

check_privilege() {
    if [[ "${EUID}" -eq 0 ]]; then
        echo "root"
    elif command -v sudo >/dev/null 2>&1; then
        echo "sudo"
    else
        echo "none"
    fi
}

resolve_go_bin() {
    if command -v go >/dev/null 2>&1; then
        command -v go
    elif [[ -x "/usr/local/go/bin/go" ]]; then
        echo "/usr/local/go/bin/go"
    elif [[ -x "${HOME}/.local/go/bin/go" ]]; then
        echo "${HOME}/.local/go/bin/go"
    else
        echo ""
    fi
}

resolve_fabric_bin_dir() {
    if [[ -n "${GOBIN:-}" ]]; then
        echo "${GOBIN}"
    elif [[ -n "${GOPATH:-}" ]]; then
        echo "${GOPATH}/bin"
    else
        echo "${HOME}/go/bin"
    fi
}

# --- System Dependency Management ---

check_package_installed() {
    local pkg="$1"
    if dpkg -s "${pkg}" >/dev/null 2>&1; then
        return 0
    elif command -v "${pkg}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

check_dependencies() {
    log_info "Verifying required system packages..."
    local -a missing_packages=()

    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if check_package_installed "${pkg}"; then
            printf "  ${C_GREEN}✓${C_RESET} %-18s (installed)\n" "${pkg}"
        else
            printf "  ${C_RED}✗${C_RESET} %-18s ${C_RED}(missing)${C_RESET}\n" "${pkg}"
            missing_packages+=("${pkg}")
        fi
    done

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        log_success "All required dependencies are satisfied!"
        MISSING_PKGS=()
        return 0
    else
        log_warn "${#missing_packages[@]} package(s) missing: ${missing_packages[*]}"
        MISSING_PKGS=("${missing_packages[@]}")
        return 1
    fi
}

install_packages() {
    local auto_yes="$1"
    local priv
    priv="$(check_privilege)"

    if [[ ${#MISSING_PKGS[@]} -eq 0 ]]; then
        log_info "No missing packages to install."
        return 0
    fi

    log_info "Preparing to install missing packages: ${MISSING_PKGS[*]}"

    local sudo_cmd=""
    if [[ "${priv}" == "none" ]]; then
        log_error "Administrative privileges required to install packages. Run as root or install sudo."
        return 1
    elif [[ "${priv}" == "sudo" ]]; then
        sudo_cmd="sudo"
    fi

    if [[ "${auto_yes}" != "true" ]]; then
        read -r -p "Proceed with package installation? [Y/n] " response
        response="${response:-y}"
        if [[ ! "${response}" =~ ^[Yy]$ ]]; then
            log_warn "Installation cancelled by user."
            return 1
        fi
    fi

    log_info "Updating package lists (apt-get update)..."
    ${sudo_cmd} apt-get update -qq

    log_info "Installing packages: ${MISSING_PKGS[*]}..."
    ${sudo_cmd} apt-get install -y "${MISSING_PKGS[@]}"

    log_success "Packages successfully installed!"
}

# --- Go Toolchain Management ---

version_ge() {
    local v1="$1"
    local v2="$2"
    v1="${v1#go}"
    v1="${v1#v}"
    v2="${v2#go}"
    v2="${v2#v}"

    if [[ "$(printf '%s\n%s\n' "${v2}" "${v1}" | sort -V | head -n1)" == "${v2}" ]]; then
        return 0
    else
        return 1
    fi
}

check_go_installed() {
    log_info "Checking Go toolchain requirement (>= ${MIN_GO_VERSION})..."
    local go_cmd
    go_cmd="$(resolve_go_bin)"

    if [[ -z "${go_cmd}" ]]; then
        log_warn "Go is not currently installed or not in PATH."
        return 1
    fi

    local go_raw_ver
    go_raw_ver="$("${go_cmd}" version 2>&1 || true)"
    local current_ver
    current_ver="$(echo "${go_raw_ver}" | grep -oE 'go[0-9]+(\.[0-9]+)+' | sed 's/^go//' || echo "unknown")"

    log_info "Detected Go version: ${C_BOLD}${current_ver}${C_RESET} (${go_raw_ver})"

    if [[ "${current_ver}" != "unknown" ]] && version_ge "${current_ver}" "${MIN_GO_VERSION}"; then
        log_success "Go version ${current_ver} satisfies requirement (>= ${MIN_GO_VERSION})."
        return 0
    else
        log_warn "Installed Go (${current_ver}) is below required ${MIN_GO_VERSION}. Upgrade needed."
        return 2
    fi
}

resolve_latest_go() {
    local arch="$1"
    log_info "Resolving latest stable Go release from ${GO_API_URL}..."

    local api_response
    if ! api_response="$(curl -fsSL "${GO_API_URL}" 2>/dev/null)"; then
        log_error "Failed to query Go release API at ${GO_API_URL}."
        return 1
    fi

    LATEST_GO_VER="$(echo "${api_response}" | jq -r '.[0].version // empty')"
    local file_json
    file_json="$(echo "${api_response}" | jq -r --arg arch "${arch}" '.[0].files[] | select(.os == "linux" and .arch == $arch and .kind == "archive")')"

    LATEST_GO_FILE="$(echo "${file_json}" | jq -r '.filename // empty')"
    LATEST_GO_HASH="$(echo "${file_json}" | jq -r '.sha256 // empty')"
    LATEST_GO_URL="https://go.dev/dl/${LATEST_GO_FILE}"

    if [[ -z "${LATEST_GO_FILE}" || -z "${LATEST_GO_HASH}" ]]; then
        log_error "Could not resolve Go download file or checksum for linux-${arch}."
        return 1
    fi

    log_success "Resolved: ${C_BOLD}${LATEST_GO_VER}${C_RESET} (${LATEST_GO_FILE})"
    return 0
}

provision_go() {
    local dry_run="$1"
    local user_space="$2"
    local arch
    arch="$(detect_arch)"

    LATEST_GO_VER=""
    LATEST_GO_FILE=""
    LATEST_GO_HASH=""
    LATEST_GO_URL=""

    resolve_latest_go "${arch}"

    local install_dir
    local bin_dir
    local sudo_req="false"

    if [[ "${user_space}" == "true" ]]; then
        install_dir="${HOME}/.local/go"
        bin_dir="${HOME}/.local/go/bin"
    else
        install_dir="/usr/local/go"
        bin_dir="/usr/local/go/bin"
        if [[ "${EUID}" -ne 0 ]]; then
            sudo_req="true"
        fi
    fi

    local temp_tarball="/tmp/${LATEST_GO_FILE}"

    if [[ "${dry_run}" == "true" ]]; then
        printf "\n%b=== DRY-RUN: Go Toolchain Provisioning ===%b\n" "${C_BOLD}${C_CYAN}" "${C_RESET}"
        log_dryrun "Architecture: linux-${arch}"
        log_dryrun "Target Version: ${LATEST_GO_VER}"
        log_dryrun "Download URL: ${LATEST_GO_URL}"
        log_dryrun "SHA256: ${LATEST_GO_HASH}"
        log_dryrun "Install Location: ${install_dir}"
        log_dryrun "Binary Output: ${bin_dir}/go"
        log_dryrun "Privilege Escalation Required: ${sudo_req}"
        printf "\n%bPlanned Commands for Target Machine:%b\n" "${C_BOLD}" "${C_RESET}"
        printf "  curl -fSL \"%s\" -o \"%s\"\n" "${LATEST_GO_URL}" "${temp_tarball}"
        printf "  echo \"%s  %s\" | sha256sum -c -\n" "${LATEST_GO_HASH}" "${temp_tarball}"
        if [[ "${sudo_req}" == "true" ]]; then
            printf "  sudo rm -rf \"%s\"\n" "${install_dir}"
            printf "  sudo tar -C /usr/local -xzf \"%s\"\n" "${temp_tarball}"
        else
            printf "  rm -rf \"%s\"\n" "${install_dir}"
            printf "  mkdir -p \"$(dirname "${install_dir}")\" && tar -C \"$(dirname "${install_dir}")\" -xzf \"%s\"\n" "${temp_tarball}"
        fi
        printf "  rm -f \"%s\"\n" "${temp_tarball}"
        printf "  export PATH=\"%s:\$PATH\"\n\n" "${bin_dir}"
        log_dryrun "Go dry-run simulation completed successfully."
        return 0
    fi

    # Live installation branch (Only executed on target host)
    log_info "Downloading ${LATEST_GO_FILE}..."
    curl -fSL "${LATEST_GO_URL}" -o "${temp_tarball}"

    log_info "Verifying archive integrity..."
    echo "${LATEST_GO_HASH}  ${temp_tarball}" | sha256sum -c -

    log_info "Extracting Go to ${install_dir}..."
    if [[ "${sudo_req}" == "true" ]]; then
        sudo rm -rf "${install_dir}"
        sudo tar -C /usr/local -xzf "${temp_tarball}"
    else
        rm -rf "${install_dir}"
        mkdir -p "$(dirname "${install_dir}")"
        tar -C "$(dirname "${install_dir}")" -xzf "${temp_tarball}"
    fi

    rm -f "${temp_tarball}"
    log_success "Go ${LATEST_GO_VER} successfully installed to ${install_dir}!"
    log_info "PATH export: export PATH=\"${bin_dir}:\$PATH\""
}

# --- Fabric AI Binary Management ---

check_fabric_installed() {
    log_info "Checking Fabric AI CLI binary status..."
    local fabric_bin=""
    local bin_dir
    bin_dir="$(resolve_fabric_bin_dir)"

    if command -v fabric >/dev/null 2>&1; then
        fabric_bin="$(command -v fabric)"
    elif [[ -x "${bin_dir}/fabric" ]]; then
        fabric_bin="${bin_dir}/fabric"
    fi

    if [[ -n "${fabric_bin}" ]]; then
        local current_ver
        current_ver="$("${fabric_bin}" --version 2>&1 || echo "unknown")"
        log_success "Fabric binary found: ${C_BOLD}${fabric_bin}${C_RESET} (${current_ver})"
        return 0
    else
        log_warn "Fabric binary not found in PATH or ${bin_dir}."
        return 1
    fi
}

resolve_fabric_release_tag() {
    log_info "Querying latest Fabric release tag from GitHub..."
    FABRIC_UPSTREAM_TAG="@latest"
    local api_resp
    if api_resp="$(curl -fsSL -H "Accept: application/vnd.github.v3+json" "${GITHUB_RELEASES_API}" 2>/dev/null)"; then
        local tag_name
        tag_name="$(echo "${api_resp}" | jq -r '.tag_name // empty')"
        if [[ -n "${tag_name}" ]]; then
            FABRIC_UPSTREAM_TAG="${tag_name}"
            log_success "Latest upstream release tag: ${C_BOLD}${tag_name}${C_RESET}"
            return 0
        fi
    fi
    log_warn "Could not fetch release tag from GitHub API; falling back to '@latest'."
    return 0
}

provision_fabric() {
    local dry_run="$1"
    local go_cmd
    go_cmd="$(resolve_go_bin)"
    local fabric_bin_dir
    fabric_bin_dir="$(resolve_fabric_bin_dir)"
    local target_fabric_bin="${fabric_bin_dir}/fabric"

    FABRIC_UPSTREAM_TAG=""
    resolve_fabric_release_tag

    if [[ "${dry_run}" == "true" ]]; then
        printf "\n%b=== DRY-RUN: Fabric AI Installation Simulation ===%b\n" "${C_BOLD}${C_CYAN}" "${C_RESET}"
        log_dryrun "Package Target: ${FABRIC_GO_PKG}"
        log_dryrun "Resolved Upstream Tag: ${FABRIC_UPSTREAM_TAG}"
        log_dryrun "Resolved Go Executable: ${go_cmd:-'(Will be /usr/local/go/bin/go on target)'}"
        log_dryrun "Target Install Directory: ${fabric_bin_dir}"
        log_dryrun "Target Binary Output: ${target_fabric_bin}"
        printf "\n%bPlanned Execution Steps for Target Machine:%b\n" "${C_BOLD}" "${C_RESET}"
        printf "  1. Environment Export:\n"
        printf "     export GOPATH=\"\${HOME}/go\"\n"
        printf "     export PATH=\"\${GOPATH}/bin:/usr/local/go/bin:\$PATH\"\n"
        printf "  2. Go Build / Download:\n"
        printf "     go install %s\n" "${FABRIC_GO_PKG}"
        printf "  3. Binary Verification:\n"
        printf "     %s --version\n" "${target_fabric_bin}"
        printf "  4. Setup & Pattern Synchronization:\n"
        printf "     %s --update\n\n" "${target_fabric_bin}"
        log_dryrun "Fabric dry-run simulation completed successfully."
        return 0
    fi

    # Live installation branch (Only executed on target host)
    if [[ -z "${go_cmd}" ]]; then
        log_error "Go executable not found. Please install the Go toolchain first."
        return 1
    fi

    log_info "Compiling and installing Fabric via Go (${FABRIC_GO_PKG})..."
    export GOPATH="${HOME}/go"
    export PATH="${fabric_bin_dir}:$(dirname "${go_cmd}"):${PATH}"

    "${go_cmd}" install "${FABRIC_GO_PKG}"

    if [[ -x "${target_fabric_bin}" ]]; then
        log_success "Fabric installed successfully at ${target_fabric_bin}!"
        log_info "Fabric version: $("${target_fabric_bin}" --version || echo 'N/A')"
    else
        log_error "Fabric installation failed: binary not found at ${target_fabric_bin}."
        return 1
    fi
}

# --- Main Execution Logic ---

main() {
    local action="check"
    local dry_run="false"
    local user_space="false"
    local auto_yes="false"
    declare -a MISSING_PKGS=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--check)
                action="check"
                shift
                ;;
            -d|--dry-run)
                action="install"
                dry_run="true"
                shift
                ;;
            -i|--install)
                action="install"
                shift
                ;;
            -u|--user-space)
                user_space="true"
                shift
                ;;
            -y|--yes)
                auto_yes="true"
                shift
                ;;
            -v|--version)
                echo "${SCRIPT_NAME} version ${VERSION}"
                exit 0
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    printf "\n${C_BOLD}=== Fabric Installer & Deployment Toolkit (v%s) ===${C_RESET}\n\n" "${VERSION}"

    local arch
    arch="$(detect_arch)"
    detect_os
    log_info "System Architecture: ${C_BOLD}${arch}${C_RESET}"

    local deps_ok="true"
    if ! check_dependencies; then
        deps_ok="false"
    fi

    local go_ok="true"
    if ! check_go_installed; then
        go_ok="false"
    fi

    local fabric_ok="true"
    if ! check_fabric_installed; then
        fabric_ok="false"
    fi

    if [[ "${action}" == "install" ]]; then
        if [[ "${dry_run}" == "true" ]]; then
            printf "\n%b=== COMPLETE DRY-RUN SIMULATION (No System Mutations) ===%b\n" "${C_BOLD}${C_CYAN}" "${C_RESET}"
            if [[ "${deps_ok}" == "false" ]]; then
                log_dryrun "Missing packages to install via apt: ${MISSING_PKGS[*]}"
                log_dryrun "Planned command: sudo apt-get update && sudo apt-get install -y ${MISSING_PKGS[*]}"
            else
                log_dryrun "All system packages are already satisfied."
            fi

            provision_go "true" "${user_space}"
            provision_fabric "true"

            printf "\n%b=== DRY-RUN COMPLETE: System left completely untouched ===%b\n\n" "${C_BOLD}${C_CYAN}" "${C_RESET}"
        else
            # Live install on target machine
            if [[ "${deps_ok}" == "false" ]]; then
                install_packages "${auto_yes}"
            fi
            if [[ "${go_ok}" == "false" ]]; then
                provision_go "false" "${user_space}"
            fi
            if [[ "${fabric_ok}" == "false" ]]; then
                provision_fabric "false"
            fi
        fi
    elif [[ "${action}" == "check" ]]; then
        printf "\n"
        if [[ "${deps_ok}" == "true" && "${go_ok}" == "true" && "${fabric_ok}" == "true" ]]; then
            log_success "All pre-flight checks passed! Fabric is fully installed."
        else
            log_warn "Pre-flight requirements incomplete. Run with '--dry-run' to preview installation."
        fi
    fi

    printf "\n${C_BOLD}=== Execution Finished ===${C_RESET}\n\n"
}

main "$@"
