#!/usr/bin/env bash
set -euo pipefail

# Linux package installation script
# Supports apt (Debian/Ubuntu) and dnf (Fedora/RHEL)

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Common packages
PACKAGES=(
    tmux
    neovim
    vim
    fzf
    ripgrep
    bat
    fd-find
    htop
    git
    zsh
    curl
    wget
)

install_apt() {
    log_info "Updating apt..."
    sudo apt update

    log_info "Installing packages with apt..."
    sudo apt install -y "${PACKAGES[@]}"

    # eza not in default repos, use cargo or manual install
    if ! command -v eza &> /dev/null; then
        log_info "Installing eza via cargo..."
        if command -v cargo &> /dev/null; then
            cargo install eza
        else
            log_info "Cargo not found. Install Rust first: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        fi
    fi

    # lazygit via PPA
    if ! command -v lazygit &> /dev/null; then
        log_info "Installing lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm lazygit lazygit.tar.gz
    fi
}

install_dnf() {
    log_info "Installing packages with dnf..."
    sudo dnf install -y "${PACKAGES[@]}" eza lazygit
}

install_starship() {
    if ! command -v starship &> /dev/null; then
        log_info "Installing starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    else
        log_success "Starship already installed"
    fi
}

main() {
    if command -v apt &> /dev/null; then
        install_apt
    elif command -v dnf &> /dev/null; then
        install_dnf
    else
        log_error "No supported package manager found (apt or dnf)"
        exit 1
    fi

    install_starship

    log_success "Linux packages installed!"
    log_info "Note: Install Nerd Fonts manually from https://www.nerdfonts.com/font-downloads"
}

main "$@"
