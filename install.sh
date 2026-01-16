#!/usr/bin/env bash
set -euo pipefail

# Dotfiles installation script
# Supports macOS and Linux with automatic backup and symlink creation

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Options
DRY_RUN=false
FORCE=false
INSTALL_PACKAGES=true

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -h, --help      Show this help message
    -n, --dry-run   Simulate without making changes
    -f, --force     Overwrite without confirmation
    --no-packages   Skip package installation

Examples:
    $(basename "$0")              # Interactive install
    $(basename "$0") --dry-run    # See what would happen
    $(basename "$0") --force      # Non-interactive install
EOF
}

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

backup_file() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_path="$BACKUP_DIR/$(basename "$target")"
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would backup: $target -> $backup_path"
        else
            cp -R "$target" "$backup_path"
            log_warn "Backed up: $target -> $backup_path"
        fi
    fi
}

create_symlink() {
    local source="$1"
    local target="$2"

    # Ensure parent directory exists
    local parent_dir
    parent_dir="$(dirname "$target")"
    if [[ ! -d "$parent_dir" ]]; then
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would create directory: $parent_dir"
        else
            mkdir -p "$parent_dir"
        fi
    fi

    # Handle existing file/symlink
    if [[ -L "$target" ]]; then
        local current_link
        current_link="$(readlink "$target")"
        if [[ "$current_link" == "$source" ]]; then
            log_success "Already linked: $target"
            return
        fi
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would remove existing symlink: $target"
        else
            rm "$target"
        fi
    elif [[ -e "$target" ]]; then
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would backup and replace: $target"
        elif ! $FORCE; then
            log_warn "File exists: $target"
            read -rp "Overwrite? [y/N] " response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log_info "Skipping: $target"
                return
            fi
            backup_file "$target"
            rm -rf "$target"
        else
            backup_file "$target"
            rm -rf "$target"
        fi
    fi

    if $DRY_RUN; then
        log_info "[DRY-RUN] Would link: $source -> $target"
    else
        ln -s "$source" "$target"
        log_success "Linked: $target -> $source"
    fi
}

install_homebrew() {
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would install Homebrew"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
    else
        log_success "Homebrew already installed"
    fi
}

install_macos_packages() {
    if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
        log_info "Installing Homebrew packages..."
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would run: brew bundle --file=$DOTFILES_DIR/Brewfile"
        else
            brew bundle --file="$DOTFILES_DIR/Brewfile"
        fi
    fi
}

install_linux_packages() {
    if [[ -f "$DOTFILES_DIR/packages-linux.sh" ]]; then
        log_info "Installing Linux packages..."
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would run: $DOTFILES_DIR/packages-linux.sh"
        else
            bash "$DOTFILES_DIR/packages-linux.sh"
        fi
    fi
}

install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$tpm_dir" ]]; then
        log_info "Installing TPM (Tmux Plugin Manager)..."
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would clone TPM to $tpm_dir"
        else
            git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
            log_success "TPM installed. Run 'prefix + I' in tmux to install plugins."
        fi
    else
        log_success "TPM already installed"
    fi
}

install_vim_plug() {
    local plug_file="$HOME/.vim/autoload/plug.vim"
    if [[ ! -f "$plug_file" ]]; then
        log_info "Installing vim-plug..."
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would download vim-plug to $plug_file"
        else
            curl -fLo "$plug_file" --create-dirs \
                https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
            log_success "vim-plug installed. Run ':PlugInstall' in vim."
        fi
    else
        log_success "vim-plug already installed"
    fi
}

create_symlinks() {
    log_info "Creating symlinks..."

    # Shell
    create_symlink "$DOTFILES_DIR/shell/zshrc" "$HOME/.zshrc"
    create_symlink "$DOTFILES_DIR/shell/zprofile" "$HOME/.zprofile"

    # Editors
    create_symlink "$DOTFILES_DIR/editors/vimrc" "$HOME/.vimrc"
    create_symlink "$DOTFILES_DIR/editors/nvim" "$HOME/.config/nvim"

    # Tools
    create_symlink "$DOTFILES_DIR/tools/tmux.conf" "$HOME/.tmux.conf"
    create_symlink "$DOTFILES_DIR/tools/starship.toml" "$HOME/.config/starship.toml"
    create_symlink "$DOTFILES_DIR/tools/ghostty" "$HOME/.config/ghostty"

    # Git
    create_symlink "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
    create_symlink "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --no-packages)
                INSTALL_PACKAGES=false
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    local os
    os="$(detect_os)"
    log_info "Detected OS: $os"
    log_info "Dotfiles directory: $DOTFILES_DIR"

    if $DRY_RUN; then
        log_warn "Running in DRY-RUN mode - no changes will be made"
    fi

    # Install packages
    if $INSTALL_PACKAGES; then
        case "$os" in
            macos)
                install_homebrew
                install_macos_packages
                ;;
            linux)
                install_linux_packages
                ;;
        esac
    fi

    # Create symlinks
    create_symlinks

    # Install plugin managers
    install_tpm
    install_vim_plug

    echo ""
    if $DRY_RUN; then
        log_info "Dry run complete. Run without --dry-run to apply changes."
    else
        log_success "Installation complete!"
        if [[ -d "$BACKUP_DIR" ]]; then
            log_info "Backups saved to: $BACKUP_DIR"
        fi
        echo ""
        log_info "Next steps:"
        echo "  1. Restart your terminal or run: source ~/.zshrc"
        echo "  2. Open tmux and press 'prefix + I' to install plugins"
        echo "  3. Open vim and run ':PlugInstall'"
        echo "  4. Open nvim (lazy.nvim will auto-bootstrap)"
    fi
}

main "$@"
