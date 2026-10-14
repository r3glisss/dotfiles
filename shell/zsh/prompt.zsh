# --------------------------------------------------------------------------- #
#             PROMPT : starship (profil full) sinon prompt natif zsh
# --------------------------------------------------------------------------- #
if [[ $DOTFILES_PROFILE == full ]] && (( $+commands[starship] )); then
    eval "$(starship init zsh)"
    return 0
fi

# Prompt natif : user@host (rouge si root), dossier, branche git, statut
autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' %F{magenta}%b%f'
zstyle ':vcs_info:git:*' actionformats ' %F{magenta}%b%f|%F{red}%a%f'
add-zsh-hook precmd vcs_info

setopt PROMPT_SUBST
PROMPT='%(!.%F{red}.%F{yellow})%n@%m%f %F{blue}%~%f${vcs_info_msg_0_} %(?.%F{green}.%F{red})❯%f '
