-- Colorschemes.
--
-- Deux colorschemes, a basculer avec :colorscheme :
--   claude-dark   -> expresso      (colors/claude-dark.vim)
--   claude-white  -> cafe au lait  (colors/claude-white.vim, auto sur markdown)
-- La palette commune est dans lib/claude_theme.vim ; chaque colorscheme pose
-- aussi `background`. Ce ne sont pas des plugins, rien a declarer ici : ce
-- fichier ne declare que les colorschemes qui viennent d'un plugin.
--
-- Options, a poser AVANT le :colorscheme
--   vim.g.claude_bold_keywords   = 0  -- mots-cles non gras
--   vim.g.claude_italic_comments = 0  -- commentaires non italiques
--   vim.g.claude_transparent     = 1  -- fond transparent
--   vim.g.claude_blue_literals   = 0  -- litteraux et operateurs en ocre
--
-- Defaut : `xcodedark` (init.lua). Autres : xcodedarkhc, xcodelight, xcodehc,
-- xcodelighthc, xcodewwdc, fournis par vim-colors-xcode ci-dessous.
--
-- lualine suit le colorscheme courant (theme = "auto"), rien a basculer avec.

return {
  {
    "lunacookies/vim-colors-xcode",
    name = "xcode",
    -- Aucune `config` : la spec ne sert qu'a poser les colorschemes sur le
    -- runtimepath. Le theme applique au demarrage est choisi dans
    -- init.lua.
    lazy = false,
    priority = 1000,
  },
}
