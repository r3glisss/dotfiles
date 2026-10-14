# --------------------------------------------------------------------------- #
#        DOTHELP : aide des dotfiles (n'affiche que ce qui est actif)
# --------------------------------------------------------------------------- #
# Usage : dothelp [section]   (sans argument : tout ; "dothelp list" : sections)

_DOTHELP_SECTIONS=(info base ls git search proc func keys edit tmux plugins macos full)

_dothelp_title() {
    local note=""
    [[ -n $2 ]] && note=" %F{8}($2)%f"
    print -P "\n%B%F{blue}== $1%f%b$note"
}
_dothelp_item() { printf "  \e[33m%-28s\e[0m %s\n" "$1" "$2" }
_dothelp_off() { print -P "  %F{8}$1%f" }

dothelp() {
    local s=${1:-all} t p name

    if [[ $s == (list|-h|--help) ]]; then
        echo "Usage : dothelp [section]"
        echo "Sections : ${_DOTHELP_SECTIONS[*]}"
        return 0
    fi
    if [[ $s != all && ${_DOTHELP_SECTIONS[(Ie)$s]} -eq 0 ]]; then
        echo "Section inconnue : $s (sections : ${_DOTHELP_SECTIONS[*]})"
        return 1
    fi

    if [[ $s == (all|info) ]]; then
        _dothelp_title "Environnement"
        _dothelp_item "profil" "$DOTFILES_PROFILE"
        _dothelp_item "config" "${ZSH_CFG_DIR:h:h}"
        _dothelp_item "ZDOTDIR" "${ZDOTDIR:-(non défini, \$HOME)}"
        _dothelp_item "plugins" "$ZSH_PLUGIN_DIR"
        _dothelp_item "historique" "$HISTFILE"
        _dothelp_item "local" "${ZDOTDIR:-$HOME}/.zshrc.local$([[ -f ${ZDOTDIR:-$HOME}/.zshrc.local ]] || echo ' (absent)')"
        _dothelp_item "prompt" "$([[ $PROMPT == *starship* ]] && echo starship || echo 'natif (vcs_info)')"
        for t in eza rg fd bat fzf nvim tmux starship; do
            p=${commands[$t]}
            [[ -z $p && $t == bat ]] && p=${commands[batcat]}
            [[ -z $p && $t == fd ]] && p=${commands[fdfind]}
            _dothelp_item "$t" "${p:-absent}"
        done
    fi

    if [[ $s == (all|base) ]]; then
        _dothelp_title "Base & navigation"
        _dothelp_item "c" "clear"
        _dothelp_item ".. / ... / ...." "remonter de 1 / 2 / 3 dossiers"
        _dothelp_item "groot" "aller à la racine du dépôt git"
        (( $+functions[zshz] )) && _dothelp_item "z <motif>" "saut vers un dossier fréquent (zsh-z)"
        _dothelp_item "python" "python3"
        _dothelp_item "cp / mv / rm" "demandent confirmation (-i)"
        _dothelp_item "grep" "grep --color=auto"
    fi

    if [[ $s == (all|ls) ]]; then
        if (( $+commands[eza] )); then
            _dothelp_title "Listing" "eza"
            _dothelp_item "ls" "dossiers en premier, icônes"
            _dothelp_item "ll / la" "liste longue (+ cachés), statut git"
            _dothelp_item "lt" "arbre complet (+ cachés)"
            _dothelp_item "l." "fichiers cachés seulement"
            _dothelp_item "tree / ltree" "arbre 3 niveaux / long 2 niveaux"
            _dothelp_item "lsf / lsd" "un par ligne / dossiers seulement"
            _dothelp_item "lss / lst" "tri par taille / par date"
        else
            _dothelp_title "Listing" "ls natif, eza absent"
            _dothelp_item "ls" "couleurs, dossiers en premier si GNU"
            _dothelp_item "ll / la" "ls -lh / ls -lah"
            _dothelp_item "l." "fichiers cachés seulement"
        fi
    fi

    if [[ $s == (all|git) ]]; then
        _dothelp_title "Git"
        _dothelp_item "g" "git"
        _dothelp_item "ga / gaa / gaddup" "add <f> / add . / add -u"
        _dothelp_item "gcommit / gca" "commit -m / commit -am"
        _dothelp_item "gst / gd / gf" "status / diff / fetch"
        _dothelp_item "gb / gbd / gco" "branch / branch -d / checkout"
        _dothelp_item "gpull / gpush" "pull / push"
        _dothelp_item "gcl" "clone"
        _dothelp_item "ggraph" "log graphique de toutes les branches"
    fi

    if [[ $s == (all|search) ]]; then
        _dothelp_title "Recherche"
        if (( $+commands[rg] )); then
            _dothelp_item "rgi <motif>" "rg insensible à la casse"
            _dothelp_item "rgf <motif>" "fichiers dont le nom correspond"
            _dothelp_item "rgl / rgc" "fichiers contenant le motif / nombre de matchs"
        else
            _dothelp_off "rg absent : rgi, rgf, rgl, rgc inactifs"
        fi
        if (( $+commands[fzf] )); then
            _dothelp_item "ff" "fzf avec preview"
            _dothelp_item "fv" "choisir un fichier et l'ouvrir dans vim"
            (( $+commands[code] )) && _dothelp_item "fe" "choisir un fichier et l'ouvrir dans VS Code"
            _dothelp_item "fcd" "cd fuzzy dans un sous-dossier"
        else
            _dothelp_off "fzf absent : ff, fv, fe, fcd inactifs"
        fi
    fi

    if [[ $s == (all|proc) ]]; then
        _dothelp_title "Processus"
        _dothelp_item "psa" "tous les processus"
        _dothelp_item "psgrep <motif>" "chercher un processus"
        _dothelp_item "psmem / pscpu" "tri par mémoire / CPU"
        (( $+functions[fzf_kill] )) && _dothelp_item "fzf_kill [sig]" "choisir des processus à tuer (Ctrl-K)"
    fi

    if [[ $s == (all|func) ]]; then
        _dothelp_title "Fonctions"
        _dothelp_item "extract <archive>" "tar, gz, bz2, xz, zip, rar, 7z…"
        _dothelp_item "bookmark <nom>" "ajouter le dossier courant à ~/.bookmarks"
        if (( $+commands[fzf] )); then
            _dothelp_item "goto" "aller à un bookmark (fzf)"
            _dothelp_item "fzf_edit [q]" "ouvrir un fichier dans \$EDITOR (Ctrl-E)"
            _dothelp_item "fzf_cd" "cd fuzzy"
            _dothelp_item "fzf_history [q]" "rappeler une commande de l'historique"
            _dothelp_item "fzf_git_branch" "checkout d'une branche (Ctrl-G)"
        else
            _dothelp_off "fzf absent : goto, fzf_* inactifs"
        fi
        _dothelp_item "dothelp [section]" "cette aide"
    fi

    if [[ $s == (all|keys) ]]; then
        _dothelp_title "Raccourcis"
        if (( $+commands[fzf] )); then
            _dothelp_item "Ctrl-T" "insérer un fichier (fzf)"
            _dothelp_item "Ctrl-R" "historique (fzf)$( (( $+commands[pbcopy] )) && echo ', Ctrl-Y copie')"
            _dothelp_item "Alt-C" "cd dans un sous-dossier (fzf)"
            _dothelp_item "Ctrl-E" "fzf_edit"
            _dothelp_item "Ctrl-G" "fzf_git_branch"
            _dothelp_item "Ctrl-K" "fzf_kill"
            _dothelp_item "dans fzf" "Ctrl-/ preview, Ctrl-U/D défiler la preview"
        else
            _dothelp_off "fzf absent : Ctrl-T/R/E/G/K et Alt-C natifs"
        fi
        if (( $+functions[history-substring-search-up] )); then
            _dothelp_item "↑ / ↓" "historique filtré par ce qui est tapé"
            _dothelp_item "k / j (vi normal)" "idem en mode vi"
        fi
        (( $+functions[_zsh_autosuggest_start] )) && _dothelp_item "→ / Fin" "accepter la suggestion grisée"
        _dothelp_item "Tab" "complétion (menu, insensible à la casse)"
    fi

    if [[ $s == (all|edit) ]]; then
        _dothelp_title "Éditeurs"
        _dothelp_item "EDITOR" "${EDITOR:-(non défini)}"
        if (( $+commands[nvim] )); then
            p=${${(f)"$(nvim --version 2>/dev/null)"}[1]#NVIM }
            _dothelp_item "nvim" "$p, config ${XDG_CONFIG_HOME:-~/.config}/${NVIM_APPNAME:-nvim}"
            _dothelp_item "  <espace>" "leader : which-key affiche les raccourcis"
            _dothelp_item "  :Lazy / :Mason" "plugins / serveurs LSP"
        else
            _dothelp_off "nvim absent"
        fi
        if (( $+aliases[vim] )); then
            _dothelp_item "vim" "config du dépôt, données $DOTFILES_VIMDIR"
        elif (( $+commands[vim] )); then
            _dothelp_item "vim" "config ${MYVIMRC:-~/.vimrc}"
        else
            _dothelp_off "vim absent"
        fi
        _dothelp_item "fv / Ctrl-E" "choisir un fichier (fzf) puis vim / \$EDITOR"
    fi

    if [[ $s == (all|tmux) ]]; then
        if (( $+commands[tmux] )); then
            local pfx=C-a
            [[ -n $DOTFILES_TMUX_CONF ]] && pfx=C-b
            _dothelp_title "Tmux" "préfixe $pfx"
            if (( $+aliases[tmux] )); then
                _dothelp_item "tmux" "serveur dédié (-L dotfiles), config $DOTFILES_TMUX_CONF"
            fi
            _dothelp_item "$pfx | / $pfx -" "split vertical / horizontal (dossier courant)"
            _dothelp_item "$pfx h/j/k/l" "aller au panneau"
            _dothelp_item "$pfx H/J/K/L" "redimensionner"
            _dothelp_item "$pfx m / x / X" "zoom / fermer panneau / fermer fenêtre"
            _dothelp_item "$pfx c" "nouvelle fenêtre (dossier courant)"
            _dothelp_item "$pfx C-h / C-l / Tab" "fenêtre précédente / suivante / dernière"
            _dothelp_item "$pfx Escape, v, y" "mode copie, sélection, copie (presse-papier)"
            _dothelp_item "$pfx /" "recherche arrière dans l'historique"
            _dothelp_item "$pfx s" "synchroniser les panneaux"
            _dothelp_item "$pfx f / g / t / S" "popups fichiers / lazygit / htop / sessions (tmux >= 3.2)"
            _dothelp_item "$pfx r" "recharger la config"
            [[ $pfx == C-b ]] && _dothelp_item "tmux dans tmux" "C-a = tmux du Mac, C-b = tmux du serveur"
        else
            _dothelp_off "tmux absent"
        fi
    fi

    if [[ $s == (all|plugins) ]]; then
        _dothelp_title "Plugins zsh" "$ZSH_PLUGIN_DIR"
        for name in zsh-completions zsh-autosuggestions zsh-history-substring-search zsh-z zsh-syntax-highlighting; do
            if [[ -d $ZSH_PLUGIN_DIR/$name ]]; then
                _dothelp_item "$name" "installé"
            else
                _dothelp_off "$name : absent"
            fi
        done
    fi

    if [[ $s == (all|macos) && $OSTYPE == darwin* ]]; then
        _dothelp_title "macOS"
        _dothelp_item "enable_shutdown" "extinction auto à 3h tous les jours (sudo)"
        _dothelp_item "disable_shutdown" "annuler l'extinction programmée (sudo)"
    fi

    if [[ $s == (all|full) && $DOTFILES_PROFILE == full ]]; then
        _dothelp_title "Profil full"
        _dothelp_item "ccusage" "usage Claude Code en direct (npx)"
        _dothelp_item "claude-serena" "serveur MCP serena sur le dossier courant"
    fi
    echo
}

_dothelp() { _values 'section' list $_DOTHELP_SECTIONS }
(( $+functions[compdef] )) && compdef _dothelp dothelp
