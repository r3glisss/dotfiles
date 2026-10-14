# --------------------------------------------------------------------------- #
#                   COMPINIT & PLUGINS (aucun clone au démarrage)
# --------------------------------------------------------------------------- #
# Plugins installés par install.sh (~/.zsh) ou lite/install.sh (profile.zsh)
: ${ZSH_PLUGIN_DIR:=$HOME/.zsh}

# zsh-completions doit être dans le fpath AVANT compinit
[[ -d "$ZSH_PLUGIN_DIR/zsh-completions/src" ]] && fpath=("$ZSH_PLUGIN_DIR/zsh-completions/src" $fpath)

# compinit complet si le dump a plus de 24h, sinon rapide (-C)
autoload -Uz compinit
_zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
_zcompdump_stale=( $_zcompdump(N.mh+24) )
if [[ ! -f $_zcompdump || -n $_zcompdump_stale ]]; then
    compinit -d "$_zcompdump"
else
    compinit -C -d "$_zcompdump"
fi
unset _zcompdump _zcompdump_stale

# Plugin configurations
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# syntax-highlighting doit rester en dernier
for _plugin in \
    zsh-autosuggestions/zsh-autosuggestions.zsh \
    zsh-history-substring-search/zsh-history-substring-search.zsh \
    zsh-z/zsh-z.plugin.zsh \
    zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
    [[ -f "$ZSH_PLUGIN_DIR/$_plugin" ]] && source "$ZSH_PLUGIN_DIR/$_plugin"
done
unset _plugin

# Key bindings for history search
if (( $+functions[history-substring-search-up] )); then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey -M vicmd 'k' history-substring-search-up
    bindkey -M vicmd 'j' history-substring-search-down
fi
