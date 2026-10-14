# --------------------------------------------------------------------------- #
#                 ÉDITEURS : EDITOR, vim/nvim isolés en profil lite
# --------------------------------------------------------------------------- #
# En lite, profile.zsh exporte (si installés par lite/install.sh) :
#   NVIM_APPNAME=nvim-dotfiles  → config ~/.config/nvim-dotfiles (lien dépôt),
#                                 données ~/.local/share/nvim-dotfiles
#   DOTFILES_VIMDIR             → plugins / undo / swap de vim hors de ~/.vim
# Les configs vim/nvim du client ne sont ni lues ni modifiées.

_dotfiles_vimrc="${ZSH_CFG_DIR:h:h}/editors/vimrc"
if [[ -n $DOTFILES_VIMDIR && -f $_dotfiles_vimrc ]] && (( $+commands[vim] )); then
    alias vim="vim -u ${(q)_dotfiles_vimrc}"
fi

# Éditeur par défaut (git, fzf_edit…) si la machine n'en impose pas
if [[ -z $EDITOR ]]; then
    if (( $+commands[nvim] )); then
        export EDITOR=nvim
    elif (( $+commands[vim] )); then
        export EDITOR=vim
        [[ -n $DOTFILES_VIMDIR ]] && EDITOR="vim -u ${(q)_dotfiles_vimrc}"
    else
        export EDITOR=vi
    fi
fi
export VISUAL=${VISUAL:-$EDITOR}
unset _dotfiles_vimrc
