-- Colorschemes.
--
-- Par defaut : `claude`, le theme maison. Ce n'est pas un plugin -- le fichier
-- vit dans colors/claude.vim a cote de cette configuration -- mais on l'applique
-- depuis une spec chargee en priorite pour qu'aucun plugin de theme ne repasse
-- derriere.
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
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      vim.cmd.colorscheme("claude")
    end,
  },
}
