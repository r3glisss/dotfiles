-- Minimal runtime for headless tests: treesitter plus the local config.
vim.opt.rtp:prepend(vim.fn.stdpath("config"))
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/nvim-treesitter")
