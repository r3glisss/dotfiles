return {
  "Exafunction/windsurf.vim",
  config = function()
    -- Basic Windsurf configuration
    vim.g.windsurf_enabled = true

    -- Optional: Set up keymaps for Windsurf
    local keymap = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- Example keymaps (adjust according to Windsurf's actual commands)
    keymap("n", "<leader>ws", ":WindsurfStart<CR>", opts)
    keymap("n", "<leader>wq", ":WindsurfStop<CR>", opts)
    keymap("n", "<leader>wr", ":WindsurfRestart<CR>", opts)
    keymap("n", "<leader>wt", ":WindsurfToggle<CR>", opts)

    -- Additional configuration options
    -- (These are examples - adjust based on actual Windsurf options)
    vim.g.windsurf_auto_start = false
    vim.g.windsurf_debug = false
  end,

  -- Optional: Load only for specific file types
  -- ft = { "python", "javascript", "typescript", "lua" },

  -- Optional: Load on specific commands
  -- cmd = { "WindsurfStart", "WindsurfStop", "WindsurfToggle" },

  -- Optional: Dependencies if needed
  -- dependencies = {
  --   "nvim-lua/plenary.nvim",
  -- },
}
