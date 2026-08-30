return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = {
    options = {
      -- `theme` est une option de `options`, pas une option de premier niveau :
      -- passee a la racine elle etait silencieusement ignoree. "auto" suit le
      -- colorscheme courant.
      theme = "auto",
      globalstatus = true,
      section_separators = { left = "", right = "" },
      component_separators = { left = "│", right = "│" },
    },
    sections = {
      lualine_a = { "mode" },
      -- Branche + compteurs de lignes ajoutees/modifiees/supprimees, alimentes
      -- par gitsigns : l'equivalent des extensions branch/hunks de vim-airline.
      lualine_b = {
        { "branch", icon = "" },
        { "diff", source = function()
          local gs = vim.b.gitsigns_status_dict
          if gs then
            return { added = gs.added, modified = gs.changed, removed = gs.removed }
          end
        end },
        { "diagnostics", sources = { "nvim_lsp" } },
      },
      lualine_c = { { "filename", path = 1 } },
      lualine_x = { "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },
}
