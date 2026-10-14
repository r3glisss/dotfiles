# --------------------------------------------------------------------------- #
#                  CORE : zsh pur, aucune dépendance externe
# --------------------------------------------------------------------------- #

# PATH : uniquement les répertoires utilisateur génériques (s'ils existent)
typeset -U path
[[ -d "$HOME/.bin" ]] && path=("$HOME/.bin" $path)
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)

# --------------------------------------------------------------------------- #
#                                  HISTORY
# --------------------------------------------------------------------------- #
export HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=10000
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# --------------------------------------------------------------------------- #
#                            COMPLETION OPTIONS
# --------------------------------------------------------------------------- #
# compinit est lancé dans plugins.zsh (après l'ajout de zsh-completions au fpath)
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt PATH_DIRS
setopt AUTO_MENU
setopt AUTO_LIST
setopt AUTO_PARAM_SLASH
unsetopt MENU_COMPLETE
unsetopt FLOW_CONTROL

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

# --------------------------------------------------------------------------- #
#                                  ALIASES
# --------------------------------------------------------------------------- #
# Basic shortcuts
alias c='clear'
alias python='python3'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ls / grep natifs (remplacés par eza dans tools.zsh si présent)
if ls --color=auto --group-directories-first -d . &>/dev/null; then
    alias ls='ls --color=auto --group-directories-first'
else
    alias ls='ls -G'
fi
alias ll='ls -lh'
alias la='ls -lah'
alias l.='ls -d .*'
alias grep='grep --color=auto'

# Safety prompts
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'

# Process management (ps auxf : GNU, surchargé dans macos.zsh)
alias psa="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'

# Git aliases
alias g='git'
alias ga='git add'
alias gaa='git add .'
alias gaddup='git add -u'
alias gb='git branch'
alias gbd='git branch -d'
alias gcommit='git commit -m'
alias gca='git commit -am'
alias gcl='git clone'
alias gco='git checkout'
alias gd='git diff'
alias gf='git fetch'
alias gpull='git pull'
alias gpush='git push'
alias gst='git status'
alias groot='cd "$(git rev-parse --show-toplevel)"'
alias ggraph="git log --all --decorate --oneline --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# --------------------------------------------------------------------------- #
#                                 FUNCTIONS
# --------------------------------------------------------------------------- #
extract() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: extract <archive_file>"
        return 1
    fi

    for file in "$@"; do
        if [[ ! -f "$file" ]]; then
            echo "Error: '$file' is not a valid file"
            continue
        fi

        case "${file:l}" in
            *.tar.bz2|*.tbz2) tar xjf "$file" ;;
            *.tar.gz|*.tgz) tar xzf "$file" ;;
            *.tar.xz|*.txz) tar xJf "$file" ;;
            *.tar) tar xf "$file" ;;
            *.bz2) bunzip2 "$file" ;;
            *.gz) gunzip "$file" ;;
            *.zip|*.cbz|*.epub) unzip "$file" ;;
            *.rar|*.cbr) unrar x "$file" ;;
            *.7z|*.cb7) 7z x "$file" ;;
            *.xz) unxz "$file" ;;
            *) echo "Error: '$file' - unknown archive method" ;;
        esac
    done
}

# Directory bookmarks (goto, avec fzf, est dans tools.zsh)
bookmark() {
    echo "$(pwd) : $1" >> ~/.bookmarks
}
