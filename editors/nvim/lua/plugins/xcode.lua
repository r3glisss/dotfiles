-- Colorschemes.
--
-- Par defaut : xcodedarkhc (variante sombre haut contraste de vim-colors-xcode),
-- le meme que le cycle de themes du .vimrc.
--
-- Le colorscheme maison `claude` est aussi disponible : le fichier vit dans
-- colors/claude.vim, a cote de cette configuration. Il gere les deux ambiances
-- avec un seul fichier, c'est `background` qui choisit :
--
--   :set background=dark  | :colorscheme claude   -> expresso
--   :set background=light | :colorscheme claude   -> cafe au lait
--
-- Options, a poser AVANT le :colorscheme
--   vim.g.claude_bold_keywords   = 0  -- mots-cles non gras
--   vim.g.claude_italic_comments = 0  -- commentaires non italiques
--   vim.g.claude_transparent     = 1  -- fond transparent
--   vim.g.claude_blue_literals   = 0  -- litteraux et operateurs en ocre
--
-- lualine suit le colorscheme courant (theme = "auto"), il n'y a rien a
-- basculer en meme temps.

return {
  "lunacookies/vim-colors-xcode",
  name = "xcode",
  lazy = false,
  priority = 1000,
  config = function()
    vim.o.background = "dark"
    vim.cmd.colorscheme("xcodedarkhc")
  end,
}
