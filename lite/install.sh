#!/usr/bin/env bash
set -euo pipefail

# Installation du profil zsh "lite" sur un serveur client, à lancer SUR le serveur :
#   git clone https://github.com/r3glisss/dotfiles.git ~/dotfiles
#   ~/dotfiles/lite/install.sh
# Sans sudo : tout va dans ~/.dotfiles-lite (ZDOTDIR) et ~/.local/bin.
# vim/nvim/tmux : configs du dépôt, isolées de celles du client (NVIM_APPNAME,
# DOTFILES_VIMDIR, tmux -L dotfiles -f) ; ~/.vimrc, ~/.config/nvim et
# ~/.tmux.conf ne sont pas touchés.
# Chaque étape est validée. Relancer le script = mise à jour.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LITE_DIR="$HOME/.dotfiles-lite"
BIN_DIR="$HOME/.local/bin"
TOOLS=(eza rg fd bat fzf nvim)
NVIM_APP="nvim-dotfiles"
NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/$NVIM_APP"
VIM_DIR="$LITE_DIR/vim"
# vim-plug figé (tag)
PLUG_VERSION=0.14.0
TMUX_CONF="$LITE_DIR/tmux.conf"
# Binaires fraîchement installés visibles des étapes suivantes (nvim, vim)
export PATH="$BIN_DIR:$PATH"
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
    --no-bins       Ne pas installer eza/rg/fd/bat/fzf/nvim dans ~/.local/bin
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

# nvim_ok <binaire> : version >= 0.11 (API utilisée par editors/nvim)
nvim_ok() {
    local v
    # NVIM_APPNAME : même --version crée ~/.local/state/<appname>
    v="$(NVIM_APPNAME="$NVIM_APP" "$1" --version 2>/dev/null | head -1)"
    v="${v#NVIM v}"
    [[ "$v" =~ ^([0-9]+)\.([0-9]+) ]] || return 1
    (( BASH_REMATCH[1] > 0 || BASH_REMATCH[2] >= 11 ))
}

# vim_ok : vim >= 8.1 avec +eval (vim-plug, vim-lsp)
vim_ok() {
    command -v vim &>/dev/null || return 1
    local out v
    out="$(vim --version 2>/dev/null)"
    [[ "$out" == *"+eval"* ]] || return 1
    v="$(head -1 <<< "$out" | sed -n 's/.*Vi IMproved \([0-9]*\.[0-9]*\).*/\1/p')"
    [[ "$v" =~ ^([0-9]+)\.([0-9]+)$ ]] || return 1
    (( BASH_REMATCH[1] > 8 || (BASH_REMATCH[1] == 8 && BASH_REMATCH[2] >= 1) ))
}

# glibc_version : "2.31", vide sans glibc (musl…)
glibc_version() {
    getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}' | cut -d. -f1,2
}

# tmux_version : "3.4" pour "tmux 3.4a" / "tmux next-3.5", vide si absent
tmux_version() {
    local v
    v="$(tmux -V 2>/dev/null)" || return 0
    v="${v#tmux }"; v="${v#next-}"
    [[ "$v" =~ ^([0-9]+)\.([0-9]+) ]] && echo "${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
}

# version_ge <a.b> <c.d>
version_ge() {
    local a1="${1%%.*}" a2="${1#*.}" b1="${2%%.*}" b2="${2#*.}"
    (( a1 > b1 || (a1 == b1 && a2 >= b2) ))
}

# Binaire nvim utilisable (le nôtre en priorité), vide sinon
nvim_bin() {
    local p
    for p in "$BIN_DIR/nvim" "$(command -v nvim 2>/dev/null || true)"; do
        [[ -n "$p" && -x "$p" ]] && nvim_ok "$p" && { echo "$p"; return 0; }
    done
    return 0
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
    for cmd in zsh git curl tar find; do
        if command -v "$cmd" &>/dev/null; then
            log_success "$cmd : $(command -v "$cmd")"
        else
            log_error "$cmd absent"
            exit 1
        fi
    done

    # Outils absents (ou déjà gérés par nous dans ~/.local/bin) = à installer.
    # nvim système trop ancien (< 0.11) : le nôtre passe devant dans le PATH.
    local t p
    for t in "${TOOLS[@]}"; do
        p="$(command -v "$t" 2>/dev/null || true)"
        if [[ -z "$p" || "$p" == "$BIN_DIR/$t" ]]; then
            MISSING_TOOLS+=("$t")
            log_info "$t : ${p:-absent} → à installer"
        elif [[ "$t" == nvim ]] && ! nvim_ok "$p"; then
            MISSING_TOOLS+=("$t")
            log_info "$t : $p ($(NVIM_APPNAME="$NVIM_APP" "$p" --version 2>/dev/null | head -1), < 0.11) → à installer"
        else
            log_success "$t : $p (système, conservé)"
        fi
    done

    # nvim n'est pas statique : x86_64 (neovim-releases) exige glibc >= 2.17,
    # aarch64 (build officiel) glibc >= 2.34 ; sinon on ne le propose pas
    local glibc need t2 kept=()
    glibc="$(glibc_version)"
    [[ "$ARCH" == aarch64 ]] && need=2.34 || need=2.17
    if [[ " ${MISSING_TOOLS[*]} " == *" nvim "* ]] && { [[ -z "$glibc" ]] || ! version_ge "$glibc" "$need"; }; then
        log_warn "nvim $ARCH exige glibc >= $need (trouvé : ${glibc:-aucune}) : nvim non installé"
        for t2 in "${MISSING_TOOLS[@]}"; do [[ "$t2" == nvim ]] || kept+=("$t2"); done
        MISSING_TOOLS=(${kept[@]+"${kept[@]}"})
    fi

    if vim_ok; then
        log_success "vim : $(command -v vim) ($(vim --version | head -1 | sed 's/ (.*//'))"
    else
        log_warn "vim absent, < 8.1 ou sans +eval : config vim non installable"
    fi
    local tv
    tv="$(tmux_version)"
    if [[ -z "$tv" ]]; then
        log_warn "tmux absent : config tmux non installée"
    elif version_ge "$tv" 3.0; then
        log_success "tmux : $(command -v tmux) ($tv)$(version_ge "$tv" 3.2 || echo ', < 3.2 : sans popups')"
    else
        log_warn "tmux $tv < 3.0 : config tmux non installable"
    fi
    for cmd in cc make; do
        command -v "$cmd" &>/dev/null || log_warn "$cmd absent : nvim sans compilation de parsers treesitter / fzf-native"
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
# Configs vim / nvim du dépôt, isolées de celles du client (si installées)
[[ -e ${XDG_CONFIG_HOME:-$HOME/.config}/nvim-dotfiles ]] && export NVIM_APPNAME=nvim-dotfiles
[[ -d $HOME/.dotfiles-lite/vim ]] && export DOTFILES_VIMDIR="$HOME/.dotfiles-lite/vim"
[[ -f $HOME/.dotfiles-lite/tmux.conf ]] && export DOTFILES_TMUX_CONF="$HOME/.dotfiles-lite/tmux.conf"
EOF
    log_success "$LITE_DIR/.zshrc -> $DOTFILES_DIR/shell/zshrc"
}

install_bins() {
    "$DOTFILES_DIR/lite/fetch-bins.sh" "$ARCH" "$BIN_DIR" "${MISSING_TOOLS[@]}"
    printf '%s\n' "${MISSING_TOOLS[@]}" >> "$LITE_DIR/bins.installed"
    sort -u -o "$LITE_DIR/bins.installed" "$LITE_DIR/bins.installed"
}

install_nvim() {
    local nvim
    mkdir -p "$(dirname "$NVIM_CONFIG")"
    ln -sfn "$DOTFILES_DIR/editors/nvim" "$NVIM_CONFIG"
    log_success "$NVIM_CONFIG -> $DOTFILES_DIR/editors/nvim"

    nvim="$(nvim_bin)"
    if [[ -z "$nvim" ]]; then
        log_warn "Aucun nvim >= 0.11 : plugins installés au premier lancement"
        return 0
    fi
    # Commits figés par lazy-lock.json (restore = install + checkout du lock)
    log_info "Plugins nvim (lazy-lock.json) avec $nvim… (log : $LITE_DIR/nvim-install.log)"
    if NVIM_APPNAME="$NVIM_APP" DOTFILES_PROFILE=lite "$nvim" --headless "+Lazy! restore" +qa \
        < /dev/null > "$LITE_DIR/nvim-install.log" 2>&1; then
        log_success "Plugins nvim installés"
    else
        log_warn "Lazy restore en erreur (voir le log) : relancer ':Lazy restore' dans nvim"
    fi
    if ! git -C "$DOTFILES_DIR" diff --quiet -- editors/nvim/lazy-lock.json; then
        log_warn "editors/nvim/lazy-lock.json modifié : 'git checkout editors/nvim/lazy-lock.json' avant le prochain pull"
    fi
}

install_vim() {
    local DOTFILES_VIMDIR_RC="$DOTFILES_DIR/editors/vimrc"
    local plug="$VIM_DIR/autoload/plug.vim"
    mkdir -p "$VIM_DIR/autoload"
    curl -fsSL "https://raw.githubusercontent.com/junegunn/vim-plug/$PLUG_VERSION/plug.vim" -o "$plug"
    log_success "vim-plug $PLUG_VERSION"

    log_info "Plugins vim (:PlugInstall)… (log : $LITE_DIR/vim-install.log)"
    if DOTFILES_VIMDIR="$VIM_DIR" vim -u "$DOTFILES_VIMDIR_RC" -N -E -s +'PlugInstall --sync' +qa \
        < /dev/null > "$LITE_DIR/vim-install.log" 2>&1; then
        log_success "Plugins vim installés dans $VIM_DIR/plugged"
    else
        log_warn "PlugInstall en erreur : relancer ':PlugInstall' dans vim"
    fi
}

install_tmux() {
    local tv term zsh_bin tools="$DOTFILES_DIR/tools/tmux"
    tv="$(tmux_version)"
    # Terminfo du serveur : tmux-256color (italique, couleurs) si connue
    if infocmp tmux-256color &>/dev/null; then term=tmux-256color; else term=screen-256color; fi
    zsh_bin="$(command -v zsh)"
    {
        echo "# Généré par lite/install.sh (tmux $tv) : ne pas éditer, relancer l'installeur"
        echo "source-file \"$tools/common.conf\""
        version_ge "$tv" 3.2 && echo "source-file \"$tools/v32.conf\""
        echo "source-file \"$tools/remote.conf\""
        echo "set -g default-terminal \"$term\""
        # Nouveaux panneaux : zsh (et donc le profil lite), même si le shell de login est bash
        echo "set -g default-shell \"$zsh_bin\""
        echo "bind r source-file \"$TMUX_CONF\" \\; display-message \"Configuration rechargée\""
    } > "$TMUX_CONF"
    log_success "$TMUX_CONF (TERM=$term, popups : $(version_ge "$tv" 3.2 && echo oui || echo non))"
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
    ZDOTDIR="$LITE_DIR" zsh -i -c '
        echo "profil=$DOTFILES_PROFILE EDITOR=$EDITOR NVIM_APPNAME=${NVIM_APPNAME:-} DOTFILES_VIMDIR=${DOTFILES_VIMDIR:-}"
        alias ls; alias vim; alias tmux
        for t in eza rg fd bat fzf nvim; do whence -p $t || echo "$t absent"; done
        (( $+commands[tmux] )) && [[ -n $DOTFILES_TMUX_CONF ]] && {
            tmux -L dotfiles-test -f $DOTFILES_TMUX_CONF new -d -s t && sleep 1 &&
            echo "tmux : prefix=$(tmux -L dotfiles-test show -gv prefix) TERM=$(tmux -L dotfiles-test show -gv default-terminal)"
            tmux -L dotfiles-test kill-server
        }
        (( $+commands[nvim] )) && nvim --headless "+lua io.write(\"colorscheme nvim : \", vim.g.colors_name or \"?\", \"\\n\")" +qa < /dev/null
        true' 2>&1
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

    if confirm "Neovim : config du dépôt" \
"$NVIM_CONFIG -> $DOTFILES_DIR/editors/nvim (NVIM_APPNAME=$NVIM_APP)
~/.config/nvim du client non touché ; données dans ~/.local/share/$NVIM_APP
Plugins aux commits de lazy-lock.json (git) ; rien n'est installé par mason"; then
        install_nvim
    fi

    if vim_ok && confirm "Vim : config du dépôt" \
"vim -u $DOTFILES_DIR/editors/vimrc (alias), données dans $VIM_DIR
~/.vimrc et ~/.vim du client non lus ni touchés
vim-plug $PLUG_VERSION puis :PlugInstall (git)"; then
        install_vim
    fi

    local tv
    tv="$(tmux_version)"
    if [[ -n "$tv" ]] && version_ge "$tv" 3.0 && confirm "Tmux : config du dépôt" \
"Génère $TMUX_CONF (tools/tmux/common.conf + remote.conf, tmux $tv)
Alias : tmux -L dotfiles -f $TMUX_CONF (serveur tmux séparé de celui du client)
Préfixe Ctrl-b (Ctrl-a reste au tmux du Mac) ; ~/.tmux.conf du client non touché ; pas de TPM"; then
        install_tmux
    fi

    install_hook

    if confirm "Tester le shell" "ZDOTDIR=$LITE_DIR zsh -i -c …"; then
        smoke_test || log_warn "Test en erreur (voir ci-dessus)"
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
            [[ "$t" == nvim && -f "$BIN_DIR/.nvim.version" ]] \
                && rm -rf "$(dirname "$BIN_DIR")/opt/nvim-$(cat "$BIN_DIR/.nvim.version")"
            rm -f "$BIN_DIR/$t" "$BIN_DIR/.$t.version"
        done < "$LITE_DIR/bins.installed"
        rmdir "$(dirname "$BIN_DIR")/opt" 2>/dev/null || true
        log_success "Binaires supprimés"
    fi

    if confirm "Supprimer la config nvim lite" \
"$NVIM_CONFIG (lien) et les données ~/.local/{share,state}/$NVIM_APP, ~/.cache/$NVIM_APP"; then
        rm -f "$NVIM_CONFIG"
        rm -rf "$HOME/.local/share/$NVIM_APP" "$HOME/.local/state/$NVIM_APP" "$HOME/.cache/$NVIM_APP"
        log_success "Config nvim lite supprimée"
    fi

    if confirm "Supprimer $LITE_DIR" "Attention : contient l'historique (.zsh_history), .zshrc.local, les plugins vim et tmux.conf
Les sessions tmux en cours (tmux -L dotfiles) ne sont pas fermées"; then
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
