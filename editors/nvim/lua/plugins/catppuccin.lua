return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  enabled = false,
  config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
        show_end_of_buffer = false,
        term_colors = false,
        dim_inactive = { enabled = false, shade = "dark", percentage = 0.15 },
        no_italic = true,
        no_bold = true,
        styles = {
          comments = {},
          conditionals = {},
          functions = {},
          keywords = {},
          strings = {},
          variables = {},
          numbers = {},
          booleans = {},
          properties = {},
          types = {},
          operators = {},
        },
        integrations = {
          blink_cmp = true,
          gitsigns = true,
          nvimtree = true,
          telescope = true,
        },
    })
      vim.cmd("colorscheme catppuccin") -- Apply the colorscheme
  end,
}
