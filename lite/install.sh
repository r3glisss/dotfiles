#!/usr/bin/env bash
set -euo pipefail

# Installation du profil zsh "lite" sur un serveur client, à lancer SUR le serveur :
#   git clone https://github.com/r3glisss/dotfiles.git ~/dotfiles
#   ~/dotfiles/lite/install.sh
# Sans sudo : tout va dans ~/.dotfiles-lite (ZDOTDIR) et ~/.local/bin.
# Chaque étape est validée. Relancer le script = mise à jour.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LITE_DIR="$HOME/.dotfiles-lite"
BIN_DIR="$HOME/.local/bin"
TOOLS=(eza rg fd bat fzf)
MARK_BEGIN='# >>> dotfiles-lite >>>'
MARK_END='# <<< dotfiles-lite <<<'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

WITH_BINS=true
UNINSTALL=false

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Installe (ou met à jour) le profil zsh lite dans ~/.dotfiles-lite.
Chaque étape demande une validation : [o]ui / [n]on (passer) / [q]uitter.

Options:
    -h, --help      Show this help message
    --no-bins       Ne pas installer eza/rg/fd/bat/fzf dans ~/.local/bin
    --uninstall     Retirer le profil lite
EOF
}

# confirm "titre" "détail…" → 0 = exécuter, 1 = passer, quitte sur q
STEP=0
confirm() {
    STEP=$((STEP + 1))
    echo ""
    echo -e "${BOLD}== Étape $STEP : $1${NC}"
    [[ -n "${2:-}" ]] && echo -e "$2" | sed 's/^/   /'
    local answer
    while true; do
        read -rp "   Exécuter ? [o/n/q] " answer < /dev/tty
        case "$answer" in
            o|O|y|Y) return 0 ;;
            n|N) log_warn "Étape passée"; return 1 ;;
            q|Q) log_info "Abandon"; exit 0 ;;
        esac
    done
}

# Retire le bloc dotfiles-lite d'un fichier (conserve permissions / lien)
remove_block() {
    local f="$1"
    [[ -f "$f" ]] || return 0
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '$0==b{s=1} !s{print} $0==e{s=0}' "$f" > "$f.dotfiles-lite.tmp"
    cat "$f.dotfiles-lite.tmp" > "$f"
    rm -f "$f.dotfiles-lite.tmp"
}

# --------------------------------------------------------------------------- #
#                                 DÉTECTION
# --------------------------------------------------------------------------- #
ARCH=""
LOGIN_SHELL=""
MISSING_TOOLS=()

detect() {
    case "$(uname -m)" in
        x86_64|amd64) ARCH=x86_64 ;;
        aarch64|arm64) ARCH=aarch64 ;;
        *) ARCH="$(uname -m)" ;;
    esac
    LOGIN_SHELL="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7 || true)"
    LOGIN_SHELL="${LOGIN_SHELL:-$SHELL}"

    log_info "Système      : $(uname -s) $ARCH"
    log_info "Shell login  : $LOGIN_SHELL"
    log_info "Dotfiles     : $DOTFILES_DIR"

    local cmd
    for cmd in zsh git curl tar; do
        if command -v "$cmd" &>/dev/null; then
            log_success "$cmd : $(command -v "$cmd")"
        else
            log_error "$cmd absent"
            exit 1
        fi
    done

    # Outils absents (ou déjà gérés par nous dans ~/.local/bin) = à installer
    local t p
    for t in "${TOOLS[@]}"; do
        p="$(command -v "$t" 2>/dev/null || true)"
        if [[ -z "$p" || "$p" == "$BIN_DIR/$t" ]]; then
            MISSING_TOOLS+=("$t")
            log_info "$t : ${p:-absent} → à installer"
        else
            log_success "$t : $p (système, conservé)"
        fi
    done
}

# --------------------------------------------------------------------------- #
#                                INSTALLATION
# --------------------------------------------------------------------------- #
install_plugins() {
    mkdir -p "$LITE_DIR/plugins"
    local name repo
    while read -r name repo; do
        [[ -z "$name" || "$name" == \#* ]] && continue
        if [[ -d "$LITE_DIR/plugins/$name/.git" ]]; then
            git -C "$LITE_DIR/plugins/$name" pull --quiet --ff-only
            log_success "Plugin $name (mis à jour)"
        else
            git clone --quiet --depth=1 "$repo" "$LITE_DIR/plugins/$name"
            log_success "Plugin $name"
        fi
    done < "$DOTFILES_DIR/shell/plugins.list"
}

install_zdotdir() {
    mkdir -p "$LITE_DIR"
    ln -sfn "$DOTFILES_DIR/shell/zshrc" "$LITE_DIR/.zshrc"

    # ZDOTDIR détourne aussi .zprofile / .zlogin : on garde ceux du client
    local f
    for f in zprofile zlogin zlogout; do
        printf '[[ -f "$HOME/.%s" ]] && source "$HOME/.%s"\n' "$f" "$f" > "$LITE_DIR/.$f"
    done

    cat > "$DOTFILES_DIR/shell/zsh/profile.zsh" << 'EOF'
# Généré par lite/install.sh (non versionné)
export DOTFILES_PROFILE=lite
export ZSH_PLUGIN_DIR="$HOME/.dotfiles-lite/plugins"
EOF
    log_success "$LITE_DIR/.zshrc -> $DOTFILES_DIR/shell/zshrc"
}

install_bins() {
    "$DOTFILES_DIR/lite/fetch-bins.sh" "$ARCH" "$BIN_DIR" "${MISSING_TOOLS[@]}"
    printf '%s\n' "${MISSING_TOOLS[@]}" >> "$LITE_DIR/bins.installed"
    sort -u -o "$LITE_DIR/bins.installed" "$LITE_DIR/bins.installed"
}

install_hook() {
    local target block
    if [[ "$LOGIN_SHELL" == */zsh ]]; then
        target="$HOME/.zshenv"
        block="$MARK_BEGIN
[[ -o interactive && ! -f \$HOME/.dotfiles-lite/disabled ]] && export ZDOTDIR=\"\$HOME/.dotfiles-lite\"
$MARK_END"
    else
        target="$HOME/.bashrc"
        block="$MARK_BEGIN
if [[ \$- == *i* && -z \$ZSH_VERSION && ! -f \$HOME/.dotfiles-lite/disabled ]] && command -v zsh >/dev/null 2>&1; then
    export ZDOTDIR=\"\$HOME/.dotfiles-lite\"
    exec zsh
fi
$MARK_END"
    fi

    confirm "Activer au login (shell de login : $LOGIN_SHELL)" \
"Ajoute ce bloc à $target (sauvegarde $target.bak-dotfiles-lite) :
$block
Sans cette étape : lancer manuellement 'ZDOTDIR=~/.dotfiles-lite zsh'" || return 0

    [[ -f "$target" && ! -f "$target.bak-dotfiles-lite" ]] && cp "$target" "$target.bak-dotfiles-lite"
    touch "$target"
    remove_block "$target"
    printf '%s\n' "$block" >> "$target"
    log_success "Bloc ajouté à $target"
}

smoke_test() {
    ZDOTDIR="$LITE_DIR" zsh -i -c 'echo "profil=$DOTFILES_PROFILE"; alias ls; for t in eza rg fd bat fzf; do whence -p $t || echo "$t absent"; done' 2>&1
}

do_install() {
    detect

    if confirm "Plugins zsh" "Clone (ou git pull) de shell/plugins.list dans $LITE_DIR/plugins"; then
        install_plugins
    fi

    if confirm "Configuration zsh (ZDOTDIR)" \
"$LITE_DIR/.zshrc -> $DOTFILES_DIR/shell/zshrc (lien : 'git pull' suffit pour mettre à jour)
Shims .zprofile/.zlogin/.zlogout vers ceux du client
Génère shell/zsh/profile.zsh (profil lite, non versionné)"; then
        install_zdotdir
    fi

    if $WITH_BINS && [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
        if confirm "Binaires dans $BIN_DIR" \
"${MISSING_TOOLS[*]} ($ARCH, versions figées dans lite/fetch-bins.sh)
Téléchargés depuis les releases GitHub"; then
            install_bins
        fi
    fi

    install_hook

    if confirm "Tester le shell" "ZDOTDIR=$LITE_DIR zsh -i -c …"; then
        smoke_test
    fi

    echo ""
    log_success "Terminé. Mise à jour : cd $DOTFILES_DIR && git pull && lite/install.sh"
    log_info "Désactivation temporaire : touch $LITE_DIR/disabled"
    log_info "Réglages propres au client : $LITE_DIR/.zshrc.local"
}

# --------------------------------------------------------------------------- #
#                               DÉSINSTALLATION
# --------------------------------------------------------------------------- #
do_uninstall() {
    if confirm "Retirer les blocs dotfiles-lite" "~/.zshenv et ~/.bashrc"; then
        remove_block "$HOME/.zshenv"
        remove_block "$HOME/.bashrc"
        log_success "Blocs retirés"
    fi

    if [[ -f "$LITE_DIR/bins.installed" ]] && confirm "Supprimer les binaires installés" \
"$(tr '\n' ' ' < "$LITE_DIR/bins.installed")(dans $BIN_DIR)"; then
        local t
        while read -r t; do
            rm -f "$BIN_DIR/$t" "$BIN_DIR/.$t.version"
        done < "$LITE_DIR/bins.installed"
        log_success "Binaires supprimés"
    fi

    if confirm "Supprimer $LITE_DIR" "Attention : contient l'historique (.zsh_history) et .zshrc.local"; then
        rm -rf "$LITE_DIR"
        rm -f "$DOTFILES_DIR/shell/zsh/profile.zsh"
        log_success "$LITE_DIR supprimé"
    fi

    log_info "Le dépôt $DOTFILES_DIR est conservé (à supprimer à la main si besoin)"
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --no-bins)
                WITH_BINS=false
                shift
                ;;
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    if $UNINSTALL; then
        do_uninstall
    else
        do_install
    fi
}

main "$@"
