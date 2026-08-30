return {
  "saghen/blink.cmp",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  version = "*",
  opts = function()
    return {
      keymap = {
        preset = "default",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    }
  end,
  opts_extend = { "sources.default" },
}
