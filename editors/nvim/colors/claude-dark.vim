" claude-dark — voir lib/claude_theme.vim pour la palette
hi clear
if exists('syntax_on')
  syntax reset
endif
let g:claude_variant = 'dark'
" colors_name est vide après `hi clear` : ce changement de 'background' ne
" recharge donc pas le colorscheme en boucle.
if &background !=# 'dark'
  set background=dark
endif
runtime lib/claude_theme.vim
