-- Colorschemes.
--
-- Le theme par defaut est `claude` (colors/claude.vim), applique dans
-- config/settings.lua : ce n'est pas un plugin, il n'a rien a faire ici.
-- Ce fichier ne declare que les colorschemes qui viennent d'un plugin.
--
-- Un seul fichier gere les deux ambiances, c'est `background` qui choisit :
--   background=dark   -> expresso
--   background=light  -> cafe au lait
--
-- Options, a poser AVANT le :colorscheme
--   vim.g.claude_bold_keywords   = 0  -- mots-cles non gras
--   vim.g.claude_italic_comments = 0  -- commentaires non italiques
--   vim.g.claude_transparent     = 1  -- fond transparent
--   vim.g.claude_blue_literals   = 0  -- litteraux et operateurs en ocre
--
-- Alternative disponible : `:colorscheme xcodedarkhc` (et xcodedark, xcodelight,
-- xcodehc, xcodelighthc, xcodewwdc), fournies par vim-colors-xcode ci-dessous.
--
-- lualine suit le colorscheme courant (theme = "auto"), rien a basculer avec.

return {
  {
    "lunacookies/vim-colors-xcode",
    name = "xcode",
    -- Aucune `config` : la spec ne sert qu'a poser les colorschemes sur le
    -- runtimepath. Le theme applique au demarrage est choisi dans
    -- config/settings.lua.
    lazy = false,
    priority = 1000,
  },
}
