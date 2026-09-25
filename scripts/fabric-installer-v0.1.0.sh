#!/bin/bash
# ==============================================================================
# Script Name: fabric-installer.sh
# Description: Automated, modular installer and deployment toolkit for
#              Daniel Miessler's Fabric on Debian 13 (Trixie) and Linux systems.
# Version:     0.1.0
# Author:      thatguyinoz <thatguy@hctech.com.au>
# Repository:  https://github.com/thatguyinoz/fabric_installer
#
# Changelog:
#   v0.1.0 - Initial foundation: OS detection, architecture resolution,
#            prerequisite dependency checking, and automated apt installation.
# ==============================================================================

set -euo pipefail

# --- Configuration & Setup ---
readonly SCRIPT_NAME="fabric-installer.sh"
readonly VERSION="0.1.0"

# Target Operating System
readonly TARGET_OS_ID="debian"
readonly TARGET_OS_CODENAME="trixie"
readonly TARGET_OS_VERSION="13"

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

# --- Usage & Documentation ---

usage() {
    cat <<EOF
${C_BOLD}Fabric Installer & Deployment Toolkit${C_RESET} (v${VERSION})

Usage: ${SCRIPT_NAME} [OPTIONS]

Options:
  -c, --check-deps      Validate system dependencies without installing
  -i, --install-deps    Install missing prerequisite packages via apt
  -y, --yes             Assume yes to confirmation prompts (non-interactive)
  -v, --version         Display script version and exit
  -h, --help            Display this help message and exit

Examples:
  ./${SCRIPT_NAME} --check-deps
  ./${SCRIPT_NAME} --install-deps --yes
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
    log_info "Detecting system architecture..."
    local raw_arch mapped_arch
    raw_arch="$(uname -m)"

    case "${raw_arch}" in
        x86_64|amd64)
            mapped_arch="amd64"
            ;;
        aarch64|arm64)
            mapped_arch="arm64"
            ;;
        *)
            mapped_arch="${raw_arch}"
            log_warn "Uncommon architecture detected: ${raw_arch}. Some binaries may require compiling from source."
            ;;
    esac

    log_info "Architecture: ${C_BOLD}${mapped_arch}${C_RESET} (Kernel: ${raw_arch})"
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

# --- Dependency Management ---

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
    log_info "Verifying required packages..."
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

# --- Main Execution Logic ---

main() {
    local action="check"
    local auto_yes="false"
    declare -a MISSING_PKGS=()

    # Parse CLI options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--check-deps)
                action="check"
                shift
                ;;
            -i|--install-deps)
                action="install"
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

    detect_os
    detect_arch >/dev/null

    local deps_ok="true"
    if ! check_dependencies; then
        deps_ok="false"
    fi

    if [[ "${action}" == "install" && "${deps_ok}" == "false" ]]; then
        install_packages "${auto_yes}"
        log_info "Re-verifying dependencies..."
        check_dependencies
    elif [[ "${deps_ok}" == "false" ]]; then
        printf "\n"
        log_info "Run './${SCRIPT_NAME} --install-deps' to install missing packages."
    fi

    printf "\n${C_BOLD}=== Dependency Check Complete ===${C_RESET}\n\n"
}

main "$@"
