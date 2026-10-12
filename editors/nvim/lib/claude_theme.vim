" =============================================================================
" claude.vim — colorscheme "café" inspiré de la palette de marque Claude
"
" Palette construite dans l'espace OKLCH : tous les accents partagent la même
" clarté (L≈0.705 en sombre, 0.52 en clair) et une chroma voisine, seule la
" teinte change. Résultat : aucune couleur ne "saute" ni ne s'efface, et tous
" les accents tiennent le contraste AA (>= 4.5:1) sur le fond.
" Les neutres (fond, texte, commentaires, gouttière) sont alignés sur une même
" teinte chaude (60°) pour l'ambiance café.
"
"   :colorscheme claude-dark   -> expresso
"   :colorscheme claude-white  -> café au lait
"
" Fichier partagé : sourcé par colors/claude-dark.vim et colors/claude-white.vim
" (qui posent g:claude_variant et 'background'). Ce n'est pas un colorscheme.
"
" Options (à mettre dans le .vimrc AVANT :colorscheme claude-*)
"   let g:claude_bold_keywords   = 0   " mots-clés non gras (défaut : 1)
"   let g:claude_italic_comments = 0   " commentaires non italiques (défaut : 1)
"   let g:claude_transparent     = 1   " fond transparent (défaut : 0)
" =============================================================================

hi clear
if exists('syntax_on')
  syntax reset
endif
let s:variant = get(g:, 'claude_variant', 'dark')
let g:colors_name = 'claude-' . s:variant

let s:bold    = get(g:, 'claude_bold_keywords', 1)   ? 'bold'   : 'NONE'
let s:italic  = get(g:, 'claude_italic_comments', 1) ? 'italic' : 'NONE'
let s:transp  = get(g:, 'claude_transparent', 0)
let s:blue_lit = get(g:, 'claude_blue_literals', 1)

if s:variant ==# 'white'
  " --- Café au lait ----------------------------------------------------------
  let s:bg       = ['#F7F2EE', 255]
  let s:bg_alt   = ['#ECE5DF', 254]
  let s:bg_sel   = ['#E1D7CF', 188]
  let s:bg_vis   = ['#EFCBBE', 223]
  let s:gutter   = ['#B4A8A0', 248]
  let s:comment  = ['#8F847C', 102]
  let s:fg_dim   = ['#6D645D', 241]
  let s:fg       = ['#3A332D', 236]
  let s:accent   = ['#A34C28', 130]   " terracotta — mots-clés
  let s:accent2  = ['#86603B',  95]   " caramel    — préprocesseur / spécial
  let s:gold     = ['#816512',  94]   " ocre       — littéraux
  let s:string   = ['#497738', 239]   " sauge      — chaînes
  let s:blue     = ['#3E6C9B',  60]   " ardoise    — fonctions
  let s:mauve    = ['#895284',  96]   " prune      — types
  let s:red      = ['#A63340', 131]   " brique     — erreurs
  let s:diff_add = ['#D2E5CB', 188]
  let s:diff_chg = ['#E9DDC1', 187]
  let s:diff_del = ['#F8D4D4', 224]
else
  " --- Expresso --------------------------------------------------------------
  let s:bg       = ['#1C1916', 234]
  let s:bg_alt   = ['#27221E', 235]
  let s:bg_sel   = ['#3A332D', 236]
  let s:bg_vis   = ['#4B3127', 237]
  let s:gutter   = ['#605750', 240]
  let s:comment  = ['#847B73', 244]
  let s:fg_dim   = ['#B5ACA5', 145]
  let s:fg       = ['#E9E1DB', 254]
  let s:accent   = ['#E3835C', 173]   " terracotta — mots-clés
  let s:accent2  = ['#C1976E', 137]   " caramel    — préprocesseur / spécial
  let s:gold     = ['#C09B34', 136]   " ocre       — littéraux
  let s:string   = ['#7CB169', 107]   " sauge      — chaînes
  let s:blue     = ['#74A4D6', 110]   " ardoise    — fonctions
  let s:mauve    = ['#C389BE', 139]   " prune      — types
  let s:red      = ['#EC6771', 203]   " brique     — erreurs
  let s:diff_add = ['#22331D', 235]
  let s:diff_chg = ['#372C11', 235]
  let s:diff_del = ['#422425', 236]
endif

let s:N = []
let s:bg_norm = s:transp ? s:N : s:bg

" claude_blue_literals : littéraux (1'b0, PRIV_LVL_M...) et opérateurs (&, |, =)
" en ardoise plutôt qu'en ocre / gris chaud.  Mettre à 0 pour revenir en arrière.
let s:lit = s:blue_lit ? s:blue : s:gold
let s:op  = s:blue_lit ? s:blue : s:fg_dim

" hi(groupe, fg, bg, attributs, [couleur du soulignement])
function! s:hi(group, fg, bg, attr, ...) abort
  let l:cmd = 'hi ' . a:group
  let l:cmd .= empty(a:fg) ? ' guifg=NONE ctermfg=NONE'
        \                  : ' guifg=' . a:fg[0] . ' ctermfg=' . a:fg[1]
  let l:cmd .= empty(a:bg) ? ' guibg=NONE ctermbg=NONE'
        \                  : ' guibg=' . a:bg[0] . ' ctermbg=' . a:bg[1]
  let l:cmd .= ' gui=' . a:attr . ' cterm=' . a:attr
  " guisp : indispensable, sinon les undercurl sont incolores
  let l:cmd .= a:0 && !empty(a:1) ? ' guisp=' . a:1[0] : ''
  execute l:cmd
endfunction

" --- Interface ---------------------------------------------------------------
call s:hi('Normal',        s:fg,      s:bg_norm, 'NONE')
call s:hi('NormalNC',      s:fg,      s:bg_norm, 'NONE')
call s:hi('NormalFloat',   s:fg,      s:bg_alt,  'NONE')
call s:hi('Cursor',        s:bg,      s:accent,  'NONE')
call s:hi('lCursor',       s:bg,      s:accent,  'NONE')
call s:hi('CursorLine',    s:N,       s:bg_alt,  'NONE')
call s:hi('CursorColumn',  s:N,       s:bg_alt,  'NONE')
call s:hi('ColorColumn',   s:N,       s:bg_alt,  'NONE')
call s:hi('LineNr',        s:gutter,  s:bg_norm, 'NONE')
call s:hi('LineNrAbove',   s:gutter,  s:bg_norm, 'NONE')
call s:hi('LineNrBelow',   s:gutter,  s:bg_norm, 'NONE')
call s:hi('CursorLineNr',  s:accent,  s:bg_alt,  'bold')
call s:hi('SignColumn',    s:gutter,  s:bg_norm, 'NONE')
call s:hi('FoldColumn',    s:gutter,  s:bg_norm, 'NONE')
call s:hi('Folded',        s:comment, s:bg_alt,  s:italic)
call s:hi('VertSplit',     s:bg_sel,  s:bg_norm, 'NONE')
call s:hi('WinSeparator',  s:bg_sel,  s:bg_norm, 'NONE')
call s:hi('Visual',        s:N,       s:bg_vis,  'NONE')
call s:hi('VisualNOS',     s:N,       s:bg_vis,  'NONE')
call s:hi('Search',        s:bg,      s:gold,    'NONE')
call s:hi('IncSearch',     s:bg,      s:accent,  'bold')
call s:hi('CurSearch',     s:bg,      s:accent,  'bold')
call s:hi('MatchParen',    s:accent,  s:bg_sel,  'bold,underline')
call s:hi('StatusLine',    s:fg,      s:bg_sel,  'NONE')
call s:hi('StatusLineNC',  s:comment, s:bg_alt,  'NONE')
call s:hi('StatusLineTerm',   s:fg,      s:bg_sel, 'NONE')
call s:hi('StatusLineTermNC', s:comment, s:bg_alt, 'NONE')
call s:hi('TabLine',       s:comment, s:bg_alt,  'NONE')
call s:hi('TabLineSel',    s:accent,  s:bg_norm, 'bold')
call s:hi('TabLineFill',   s:N,       s:bg_alt,  'NONE')
call s:hi('Pmenu',         s:fg,      s:bg_alt,  'NONE')
call s:hi('PmenuSel',      s:bg,      s:accent,  'bold')
call s:hi('PmenuKind',     s:mauve,   s:bg_alt,  'NONE')
call s:hi('PmenuKindSel',  s:bg,      s:accent,  'bold')
call s:hi('PmenuExtra',    s:comment, s:bg_alt,  'NONE')
call s:hi('PmenuExtraSel', s:bg,      s:accent,  'NONE')
call s:hi('PmenuMatch',    s:gold,    s:bg_alt,  'bold')
call s:hi('PmenuMatchSel', s:bg,      s:accent,  'bold,underline')
call s:hi('PmenuSbar',     s:N,       s:bg_alt,  'NONE')
call s:hi('PmenuThumb',    s:N,       s:gutter,  'NONE')
call s:hi('WildMenu',      s:bg,      s:accent,  'bold')
call s:hi('NonText',       s:gutter,  s:N,       'NONE')
call s:hi('SpecialKey',    s:gutter,  s:N,       'NONE')
call s:hi('Whitespace',    s:gutter,  s:N,       'NONE')
call s:hi('EndOfBuffer',   s:bg,      s:N,       'NONE')
call s:hi('Directory',     s:blue,    s:N,       'bold')
call s:hi('Title',         s:accent,  s:N,       'bold')
call s:hi('Question',      s:string,  s:N,       'NONE')
call s:hi('MoreMsg',       s:string,  s:N,       'NONE')
call s:hi('ModeMsg',       s:fg_dim,  s:N,       'bold')
call s:hi('WarningMsg',    s:gold,    s:N,       'NONE')
call s:hi('ErrorMsg',      s:red,     s:N,       'bold')
call s:hi('Error',         s:red,     s:N,       'bold')
call s:hi('Conceal',       s:gutter,  s:N,       'NONE')
call s:hi('Ignore',        s:comment, s:N,       'NONE')
call s:hi('Underlined',    s:blue,    s:N,       'underline')
call s:hi('Todo',          s:gold,    s:bg_alt,  'bold')
call s:hi('QuickFixLine',  s:N,       s:bg_sel,  'NONE')

" --- Syntaxe -----------------------------------------------------------------
" Mots-clés : terracotta + gras (comme xcodedarkhc), c'est l'ancre visuelle
call s:hi('Statement',     s:accent,  s:N, s:bold)
call s:hi('Keyword',       s:accent,  s:N, s:bold)
call s:hi('Conditional',   s:accent,  s:N, s:bold)
call s:hi('Repeat',        s:accent,  s:N, s:bold)
call s:hi('Label',         s:accent,  s:N, s:bold)
call s:hi('Exception',     s:red,     s:N, s:bold)

call s:hi('Comment',       s:comment, s:N, s:italic)
call s:hi('Constant',      s:lit,     s:N, 'NONE')
call s:hi('String',        s:string,  s:N, 'NONE')
call s:hi('Character',     s:string,  s:N, 'NONE')
call s:hi('Number',        s:lit,     s:N, 'NONE')
call s:hi('Boolean',       s:lit,     s:N, 'NONE')
call s:hi('Float',         s:lit,     s:N, 'NONE')
call s:hi('Identifier',    s:fg,      s:N, 'NONE')
call s:hi('Function',      s:blue,    s:N, 'bold')
call s:hi('Operator',      s:op,      s:N, 'NONE')
call s:hi('Delimiter',     s:fg_dim,  s:N, 'NONE')
" Types : prune, famille distincte des littéraux (ocre)
call s:hi('Type',          s:mauve,   s:N, 'NONE')
call s:hi('StorageClass',  s:mauve,   s:N, 'NONE')
call s:hi('Structure',     s:mauve,   s:N, 'NONE')
call s:hi('Typedef',       s:mauve,   s:N, 'NONE')
" Préprocesseur / spécial : caramel, volontairement moins saturé
call s:hi('PreProc',       s:accent2, s:N, 'NONE')
call s:hi('Include',       s:accent2, s:N, 'NONE')
call s:hi('Define',        s:accent2, s:N, 'NONE')
call s:hi('Macro',         s:accent2, s:N, 'NONE')
call s:hi('PreCondit',     s:accent2, s:N, 'NONE')
call s:hi('Special',       s:accent2, s:N, 'NONE')
call s:hi('SpecialChar',   s:accent2, s:N, 'NONE')
call s:hi('Tag',           s:accent2, s:N, 'NONE')
call s:hi('SpecialComment',s:fg_dim,  s:N, s:italic)
call s:hi('Debug',         s:red,     s:N, 'NONE')

" --- Verilog / SystemVerilog --------------------------------------------------
" vim-polyglot lie verilogOperator a Special (caramel) et y range aussi toute la
" ponctuation ; ~/.vim/after/syntax/verilog_ops.vim isole verilogPunct.
hi! link verilogOperator       Operator
hi! link systemverilogOperator Operator
hi! link verilogConstant       Constant
hi! link verilogNumber         Number

" --- Diff --------------------------------------------------------------------
" Fonds teintés plutôt qu'un texte coloré : le code reste lisible dans un diff
call s:hi('DiffAdd',     s:N,      s:diff_add, 'NONE')
call s:hi('DiffChange',  s:N,      s:diff_chg, 'NONE')
call s:hi('DiffDelete',  s:red,    s:diff_del, 'NONE')
call s:hi('DiffText',    s:N,      s:bg_sel,   'bold')
call s:hi('diffAdded',   s:string, s:N,        'NONE')
call s:hi('diffRemoved', s:red,    s:N,        'NONE')
call s:hi('diffChanged', s:gold,   s:N,        'NONE')
call s:hi('diffFile',    s:accent, s:N,        'bold')
call s:hi('diffLine',    s:blue,   s:N,        'NONE')

" --- Orthographe (guisp obligatoire pour colorer l'undercurl) -----------------
call s:hi('SpellBad',   s:N, s:N, 'undercurl', s:red)
call s:hi('SpellCap',   s:N, s:N, 'undercurl', s:gold)
call s:hi('SpellLocal', s:N, s:N, 'undercurl', s:blue)
call s:hi('SpellRare',  s:N, s:N, 'undercurl', s:mauve)

" --- vim-lsp / asyncomplete --------------------------------------------------
call s:hi('LspErrorText',       s:red,     s:bg_norm, 'bold')
call s:hi('LspWarningText',     s:gold,    s:bg_norm, 'NONE')
call s:hi('LspInformationText', s:blue,    s:bg_norm, 'NONE')
call s:hi('LspHintText',        s:comment, s:bg_norm, 'NONE')
call s:hi('LspErrorHighlight',       s:N, s:N, 'undercurl', s:red)
call s:hi('LspWarningHighlight',     s:N, s:N, 'undercurl', s:gold)
call s:hi('LspInformationHighlight', s:N, s:N, 'undercurl', s:blue)
call s:hi('LspHintHighlight',        s:N, s:N, 'undercurl', s:comment)
call s:hi('LspErrorVirtualText',       s:red,     s:N, s:italic)
call s:hi('LspWarningVirtualText',     s:gold,    s:N, s:italic)
call s:hi('LspInformationVirtualText', s:comment, s:N, s:italic)
call s:hi('LspHintVirtualText',        s:comment, s:N, s:italic)
call s:hi('LspReference',       s:N,      s:bg_sel, 'NONE')
call s:hi('LspCodeActionText',  s:gold,   s:N,      'NONE')
hi! link lspReference LspReference

" --- NERDTree / devicons -----------------------------------------------------
call s:hi('NERDTreeDir',        s:blue,    s:N, 'bold')
call s:hi('NERDTreeDirSlash',   s:gutter,  s:N, 'NONE')
call s:hi('NERDTreeOpenable',   s:accent,  s:N, 'NONE')
call s:hi('NERDTreeClosable',   s:accent,  s:N, 'NONE')
call s:hi('NERDTreeFile',       s:fg,      s:N, 'NONE')
call s:hi('NERDTreeExecFile',   s:string,  s:N, 'NONE')
call s:hi('NERDTreeLinkFile',   s:mauve,   s:N, 'NONE')
call s:hi('NERDTreeCWD',        s:accent,  s:N, 'bold')
call s:hi('NERDTreeHelp',       s:comment, s:N, s:italic)
call s:hi('NERDTreeGitStatusModified',  s:gold,    s:N, 'NONE')
call s:hi('NERDTreeGitStatusStaged',    s:string,  s:N, 'NONE')
call s:hi('NERDTreeGitStatusUntracked', s:blue,    s:N, 'NONE')
call s:hi('NERDTreeGitStatusRenamed',   s:mauve,   s:N, 'NONE')
call s:hi('NERDTreeGitStatusIgnored',   s:gutter,  s:N, 'NONE')
call s:hi('NERDTreeGitStatusDirDirty',  s:accent2, s:N, 'NONE')

" --- vim-gitgutter -----------------------------------------------------------
call s:hi('GitGutterAdd',          s:string,  s:bg_norm, 'NONE')
call s:hi('GitGutterChange',       s:gold,    s:bg_norm, 'NONE')
call s:hi('GitGutterDelete',       s:red,     s:bg_norm, 'NONE')
call s:hi('GitGutterChangeDelete', s:accent,  s:bg_norm, 'NONE')

" --- vista.vim ---------------------------------------------------------------
call s:hi('VistaTag',       s:accent,  s:N, 'bold')
call s:hi('VistaScope',     s:mauve,   s:N, 'NONE')
call s:hi('VistaKind',      s:accent2, s:N, 'NONE')
call s:hi('VistaScopeKind', s:blue,    s:N, 'NONE')
call s:hi('VistaPrefix',    s:gutter,  s:N, 'NONE')
call s:hi('VistaLineNr',    s:comment, s:N, 'NONE')
call s:hi('VistaColon',     s:gutter,  s:N, 'NONE')
call s:hi('VistaIcon',      s:gold,    s:N, 'NONE')
call s:hi('VistaFloat',     s:fg,      s:bg_alt, 'NONE')

" --- context.vim / undotree / visual-multi / easymotion -----------------------
call s:hi('ContextPopup',  s:fg_dim,  s:bg_alt, 'NONE')
call s:hi('ContextPreview', s:fg_dim, s:bg_alt, 'NONE')
call s:hi('ContextPreviewBorder', s:gutter, s:bg_alt, 'NONE')
call s:hi('UndotreeNode',        s:accent,  s:N, 'NONE')
call s:hi('UndotreeNodeCurrent', s:gold,    s:N, 'bold')
call s:hi('UndotreeSeq',         s:comment, s:N, 'NONE')
call s:hi('UndotreeCurrent',     s:accent,  s:N, 'bold')
call s:hi('UndotreeSavedSmall',  s:string,  s:N, 'NONE')
call s:hi('UndotreeSavedBig',    s:string,  s:N, 'bold')
call s:hi('UndotreeTimeStamp',   s:gutter,  s:N, 'NONE')
call s:hi('VM_Mono',   s:bg, s:gold,   'NONE')
call s:hi('VM_Extend', s:N,  s:bg_vis, 'NONE')
call s:hi('VM_Cursor', s:bg, s:accent, 'NONE')
call s:hi('VM_Insert', s:bg, s:string, 'NONE')
call s:hi('EasyMotionTarget',        s:accent, s:N, 'bold')
call s:hi('EasyMotionTarget2First',  s:accent, s:N, 'bold')
call s:hi('EasyMotionTarget2Second', s:gold,   s:N, 'bold')
call s:hi('EasyMotionShade',         s:gutter, s:N, 'NONE')
call s:hi('EasyMotionIncSearch',     s:bg,     s:accent, 'bold')

" --- fzf.vim (lu à chaque appel, donc modifiable ici) ------------------------
if !exists('g:fzf_colors')
  let g:fzf_colors = {
        \ 'fg':      ['fg', 'Normal'],
        \ 'bg':      ['bg', 'Normal'],
        \ 'hl':      ['fg', 'Statement'],
        \ 'fg+':     ['fg', 'CursorLine', 'CursorLine', 'Normal'],
        \ 'bg+':     ['bg', 'CursorLine', 'CursorLine'],
        \ 'hl+':     ['fg', 'Title'],
        \ 'info':    ['fg', 'Comment'],
        \ 'border':  ['fg', 'LineNr'],
        \ 'prompt':  ['fg', 'Function'],
        \ 'pointer': ['fg', 'Title'],
        \ 'marker':  ['fg', 'Type'],
        \ 'spinner': ['fg', 'Constant'],
        \ 'header':  ['fg', 'Comment'] }
endif

" --- Terminal intégré --------------------------------------------------------
let g:terminal_ansi_colors = [
      \ s:bg[0], s:red[0], s:string[0], s:gold[0],
      \ s:blue[0], s:mauve[0], s:accent2[0], s:fg_dim[0],
      \ s:gutter[0], s:red[0], s:string[0], s:gold[0],
      \ s:blue[0], s:mauve[0], s:accent[0], s:fg[0] ]

delfunction s:hi
