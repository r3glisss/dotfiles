# --------------------------------------------------------------------------- #
#        OUTILS OPTIONNELS : eza, rg, fd, bat, fzf (activés si présents)
# --------------------------------------------------------------------------- #
# Debian/Ubuntu nomment bat/fd "batcat"/"fdfind"
_bat=${${commands[bat]:+bat}:-${commands[batcat]:+batcat}}
_fd=${${commands[fd]:+fd}:-${commands[fdfind]:+fdfind}}
[[ $_bat == batcat ]] && alias bat='batcat'
[[ $_fd == fdfind ]] && alias fd='fdfind'

# Commandes de preview (fallback cat / ls si bat / eza absents)
if [[ -n $_bat ]]; then
    _preview_file="$_bat --style=numbers --color=always --line-range :500 {}"
else
    _preview_file="head -500 {}"
fi
if (( $+commands[eza] )); then
    _preview_dir="eza --tree --color=always --icons=auto {} | head -200"
else
    _preview_dir="ls -la {}"
fi

# --------------------------------------------------------------------------- #
#                                    EZA
# --------------------------------------------------------------------------- #
if (( $+commands[eza] )); then
    alias ls='eza --color=always --group-directories-first --icons=auto'
    alias ll='eza -l --color=always --group-directories-first --icons=auto --git'
    alias la='eza -la --color=always --group-directories-first --icons=auto --git'
    alias lt='eza -aT --color=always --group-directories-first --icons=auto'
    alias l.='eza -a | grep "^\."'
    alias tree='eza --tree --level=3 --icons=auto'
    alias ltree='eza --tree --long --level=2 --icons=auto --git'
    alias lsf='eza -1 --icons=auto'
    alias lsd='eza -D --icons=auto'
    alias lss='eza -alh --sort=size --icons=auto'
    alias lst='eza -alt --sort=modified --icons=auto'
fi

# --------------------------------------------------------------------------- #
#                                  RIPGREP
# --------------------------------------------------------------------------- #
if (( $+commands[rg] )); then
    alias rgi='rg -i'
    alias rgf='rg --files | rg'
    alias rgl='rg --files-with-matches'
    alias rgc='rg --count'
fi

# --------------------------------------------------------------------------- #
#                                    TMUX
# --------------------------------------------------------------------------- #
# Lite : config du dépôt (générée par lite/install.sh) sur un serveur tmux
# dédié (-L dotfiles), séparé des sessions et du ~/.tmux.conf du client.
if [[ -n $DOTFILES_TMUX_CONF && -f $DOTFILES_TMUX_CONF ]] && (( $+commands[tmux] )); then
    alias tmux="tmux -L dotfiles -f ${(q)DOTFILES_TMUX_CONF}"
fi

# --------------------------------------------------------------------------- #
#                                    FZF
# --------------------------------------------------------------------------- #
(( $+commands[fzf] )) || { unset _bat _fd _preview_file _preview_dir; return 0 }

if [[ -n $_fd ]]; then
    export FZF_DEFAULT_COMMAND="$_fd --type f --hidden --follow --exclude .git --exclude node_modules"
    export FZF_CTRL_T_COMMAND="$_fd --type f --hidden --follow --exclude .git"
    export FZF_ALT_C_COMMAND="$_fd --type d --hidden --follow --exclude .git"
fi

export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --margin=1
  --padding=1
  --info=inline
  --prompt="🔍 "
  --pointer="▶"
  --marker="✓"
  --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
  --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
  --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
  --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
  --preview-window=right:50%:wrap
  --bind="ctrl-u:preview-page-up,ctrl-d:preview-page-down"
  --bind="ctrl-/:toggle-preview"
  --bind="alt-up:preview-up,alt-down:preview-down"
'

export FZF_CTRL_T_OPTS="
  --preview '([[ -f {} ]] && $_preview_file) || ([[ -d {} ]] && $_preview_dir)'
  --preview-window='right:60%:wrap'
"
export FZF_ALT_C_OPTS="
  --preview '$_preview_dir'
  --preview-window='right:50%:wrap'
"
export FZF_CTRL_R_OPTS='
  --preview "echo {}"
  --preview-window "down:3:wrap"
'
# Copie presse-papier (CTRL-Y) : seulement si un outil est dispo (pbcopy sur macOS)
if (( $+commands[pbcopy] )); then
    FZF_CTRL_R_OPTS+='
  --bind "ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort"
  --header "Press CTRL-Y to copy command into clipboard"
'
fi

# Aliases
alias ff="fzf --preview '$_preview_file'"
alias fcd="cd \$(${_fd:-find . -type d} ${_fd:+--type d} | fzf --preview '$_preview_dir')"
alias fv="vim \$(fzf --preview '$_preview_file')"
(( $+commands[code] )) && alias fe="code \$(fzf --preview '$_preview_file')"

# Fuzzy find and edit
fzf_edit() {
    local file
    file=$(fzf --query="$1" --preview "$_preview_file") && ${=EDITOR:-vim} "$file"
}

# Fuzzy find and cd with preview
fzf_cd() {
    local dir
    dir=$(${_fd:-find . -type d} ${_fd:+--type d} | fzf --preview "$_preview_dir") && cd "$dir"
}

# Fuzzy kill process
fzf_kill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --header='[kill:process]' | awk '{print $2}')
    if [[ -n $pid ]]; then
        echo $pid | xargs kill -${1:-9}
    fi
}

# Fuzzy git branch checkout
fzf_git_branch() {
    git branch -a | grep -v HEAD | sed 's/remotes\/origin\///' | sort -u | fzf --header='[git:branch]' | xargs git checkout
}

# Fuzzy history search with execution
fzf_history() {
    local cmd
    cmd=$(history | fzf --tac --no-sort --query="$*" | sed 's/^ *[0-9]* *//')
    if [[ -n $cmd ]]; then
        print -z "$cmd"
    fi
}

goto() {
    local dest
    dest=$(cat ~/.bookmarks 2>/dev/null | fzf --delimiter=' : ' --with-nth=2 --preview='echo "Path: {1}"' | cut -d' ' -f1)
    [[ -n $dest ]] && cd "$dest"
}

zle -N fzf_edit
zle -N fzf_git_branch
zle -N fzf_kill
bindkey '^E' fzf_edit
bindkey '^G' fzf_git_branch
bindkey '^K' fzf_kill

# Intégration shell (CTRL-T / CTRL-R / ALT-C) : ~/.fzf.zsh ou fzf >= 0.48
if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
else
    source <(fzf --zsh 2>/dev/null)
fi
