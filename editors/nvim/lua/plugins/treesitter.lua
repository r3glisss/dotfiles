-- ~/.config/nvim/lua/plugins/treesitter.lua
--
-- Epingle sur `master`. La branche `main` (reecriture v1.0) exige Neovim >= 0.12
-- (nightly) ; en 0.11 elle plante des l'installation d'un parser
-- (`vim.list.unique` n'existe pas encore). Upstream recommande explicitement
-- master pour 0.11. A rebasculer sur `main` le jour ou nvim passe en 0.12 --
-- l'API change alors completement (plus de `nvim-treesitter.configs`, plus
-- d'`ensure_installed`, coloration allumee par `vim.treesitter.start`).
--
-- La config passe par `opts` (et non un `config` avec une table en dur) : c'est
-- ce qui permet aux autres specs -- systemverilog.lua -- d'ajouter leurs
-- parsers. `opts_extend` concatene ces listes au lieu de les ecraser, quel que
-- soit l'ordre d'import des fichiers de plugins.

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  -- Pas de lazy-loading : le plugin pose ses autocmd FileType a son chargement,
  -- et un chargement sur BufReadPost arriverait trop tard pour le tout premier
  -- buffer (FileType a deja ete emis) -- pas de coloration.
  lazy = false,
  opts_extend = { "ensure_installed", "indent.disable" },
  opts = {
    ensure_installed = {
      "c",
      "cpp",
      "lua",
      "python",
      "query",
      "vim",
      "vimdoc",
    },
    sync_install = false,
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
      disable = {},
    },
  },
  config = function(_, opts)
    -- Sans compilateur C (serveur client) aucun parser ne peut etre compile :
    -- on s'en tient a ceux livres avec nvim (c, lua, markdown, query, vim,
    -- vimdoc) au lieu d'echouer a chaque ouverture de fichier.
    local has_cc = vim.iter({ "cc", "gcc", "clang" }):any(function(c)
      return vim.fn.executable(c) == 1
    end)
    if not has_cc then
      opts.ensure_installed = {}
      opts.auto_install = false
    end
    require("nvim-treesitter.configs").setup(opts)
  end,
}
